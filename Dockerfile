# ---------- Etapa 1: build ----------
# Imagem com Maven 3.9 e JDK 21. "build" é o nome da etapa.
FROM maven:3.9-eclipse-temurin-21 AS build

# Diretório de trabalho dentro da imagem.
WORKDIR /app

# Copia primeiro apenas o pom.xml.
# Enquanto ele não mudar, o Docker reaproveita a camada de dependências abaixo.
COPY pom.xml .

# Baixa antecipadamente dependências e plugins (-B = modo não interativo).
# O "|| true" evita que uma falha deste passo opcional de cache
# interrompa o build; o que faltar é baixado no próximo RUN.
RUN mvn -B dependency:go-offline || true

# Copia código-fonte e recursos.
COPY src ./src

# clean: apaga target/ anterior.
# package: compila e empacota, gerando o JAR em target/.
# -DskipTests: os testes rodam no CI (mvnw verify), não no build da imagem.
RUN mvn -B clean package -DskipTests

# ---------- Etapa 2: runtime ----------
# Apenas JRE 21: sem Maven e sem código-fonte na imagem final.
FROM eclipse-temurin:21-jre

WORKDIR /app

# Copia o JAR gerado na etapa "build" e o renomeia para app.jar.
COPY --from=build /app/target/*.jar app.jar

# Documentação da porta. Não abre nem publica porta:
# a porta real vem de server.port=${PORT:8080}, e o Render injeta PORT.
EXPOSE 10000

# Comando executado quando o contêiner inicia.
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
