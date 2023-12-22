#!/usr/bin/env bash
: "${RANDOM_STRING?}"
: "${SERVER_KEYSTORE_STOREPASS?}"
: "${SERVER_TRUSTSTORE_STOREPASS?}"

##
echo "Install the base tools"

apt-get update
apt-get install -y \
 curl vim wget htop unzip gnupg2 netcat-traditional \
 bash-completion git apt-transport-https ca-certificates \
 software-properties-common

## Run pre-install scripts
sh /mnt/setup-ca.sh


##
echo "Install JDK"

## Retrieve the latest Linux Corretto .tgz package by using a Permanent URL
wget https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.tar.gz

mkdir -p /usr/lib/jvm/jdk-8
tar -xvf *.tar.gz -C /usr/lib/jvm/jdk-8 --strip-components 1
/usr/lib/jvm/jdk-8/bin/java -version

update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk-8/bin/java" 0
update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/jdk-8/bin/javac" 0
update-alternatives --install "/usr/bin/keytool" "keytool" "/usr/lib/jvm/jdk-8/bin/keytool" 0

update-alternatives --set java /usr/lib/jvm/jdk-8/bin/java
update-alternatives --set javac /usr/lib/jvm/jdk-8/bin/javac
update-alternatives --set keytool /usr/lib/jvm/jdk-8/bin/keytool

echo 'JAVA_HOME="/usr/lib/jvm/jdk-8"' >> /etc/environment
echo "Verify Java version"
java -version


## Ofbiz
echo "Create Dedicated System Account."
groupadd ofbizgroup
useradd -g ofbizgroup -d /opt/ofbiz -s /bin/nologin ofbiz

echo "Extract to opt directory."
wget https://dlcdn.apache.org/ofbiz/apache-ofbiz-18.12.10.zip
unzip apache-ofbiz-*.zip -d /opt/
mv /opt/apache-ofbiz-* /opt/ofbiz

echo "Load OFBiz demo data in the embedded Apache Derby database"
cd /opt/ofbiz
./gradle/init-gradle-wrapper.sh
./gradlew cleanAll loadAll

echo "Final chown"
chown -R ofbiz:ofbizgroup /opt/ofbiz

echo "Create systemctl file"
cat << EOF > /etc/systemd/system/ofbiz.service
[Unit]
Description=Ofbiz Finance Service
Wants=network.target
After=network.target

[Service]
Type=forking

Environment=OFBIZ_HOME=/opt/ofbiz
Environment=OFBIZ_LOG=/opt/ofbiz/runtime/logs/console.log
Environment='JAVA_OPTS=-Djava.awt.headless=true'

ExecStart='nohup /opt/ofbiz/gradlew ofbiz >> /opt/ofbiz/nohup.out & echo $! > /opt/ofbiz/nohup.pid &'
ExecStop='kill -9 \`cat /opt/ofbiz/nohup.pid\`'

SuccessExitStatus=143

User=ofbiz
Group=ofbizgroup
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Daemon reload & start"
systemctl daemon-reload
systemctl start ofbiz

echo "You should now be able to access Ofbiz."
