###############################
# Stage 1 — Build with Ant
###############################
FROM frekele/ant:1.10-jdk8 AS builder

# Set the working directory where build.xml is located
WORKDIR /app

# Copy the entire project
COPY . /app

# Run Ant build
RUN ant -f build.xml deploy


###############################
# Stage 2 — WildFly with built WAR
###############################
FROM jboss/wildfly:10.1.0.Final

# WildFly deployments directory
ENV DEPLOY_DIR=/opt/jboss/wildfly/standalone/deployments

# Copy the exploded WAR from builder stage into WildFly deploy folder
COPY --from=builder /opt/wildfly/standalone/deployments/kolotv.war ${DEPLOY_DIR}/kolotv.war

# Create marker
RUN touch ${DEPLOY_DIR}/kolotv.war.dodeploy

# --- CORRECTION ICI ---
# On utilise ENV pour modifier JAVA_OPTS. C'est la méthode officielle pour que Wildfly
# prenne en compte les paramètres au démarrage de Java.
ENV JAVA_OPTS="$JAVA_OPTS -Duser.language=fr -Duser.country=FR -Duser.timezone=Europe/Paris -Duser.region=FR -Djava.net.preferIPv4Stack=true"

EXPOSE 8080 9990

# On remet le CMD standard, car JAVA_OPTS fera le travail automatiquement
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]