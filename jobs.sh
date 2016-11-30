#!/bin/bash
#
# Para preparar o ambiente, faça o seguinte:
#
# 1. Criar service account:
#   $ oc create serviceaccount $DEPLOYMENTCONFIG -n $NAMESPACE
#
# 2. Dar permissao edit no projeto
#   $ oc policy add-role-to-group edit $DEPLOYMENTCONFIG -n $NAMESPACE
#
# 3. Pegar nome de um secret do novo service account
#   $ SECRET_NAME=`oc get secrets -n $NAMESPACE | awk '/^${DEPLOYMENTCONFIG}-token/{print $1; exit}'`
#   or
#   $ SECRET_NAME=`oc get secrets -n $NAMESPACE | grep ^$DEPLOYMENTCONFIG-token | head -n1 | awk '{print $1}'`
#
# 4. Montar o secret dentro do container
#   $ oc volumes dc/$DEPLOYMENTCONFIG --add -m /etc/secrets --secret-name $SECRET_NAME
#
# 5. Agora é só executar este script de dentro do container para escalar a aplicação
#   $ /path/to/script $NAMESPACE $DEPLOYMENTCONFIG 3
#

if [ $# -ne 3 ]; then
    echo "Invalid parameters"
    echo "Use: $0 namespace deploymentConfig replicas"
    exit 1
fi

NAMESPACE=$1
DEPLOYMENTCONFIG=$2
REPLICAS=$3

SECRET_CA_FILE=/etc/secrets/$DEPLOYMENTCONFIG/ca.crt
SECRET_TOKEN_FILE=/etc/secrets/$DEPLOYMENTCONFIG/token

if ! [ -s $SECRET_CA_FILE ]; then
    echo "$SECRET_CA_FILE: file empty or not found"
    exit 1
fi

if ! [ -s "$SECRET_TOKEN_FILE" ]; then
    echo "$SECRET_TOKEN_FILE: file empty or not found"
    exit 1
fi

curl https://api.getupcloud.com/oapi/v1/namespaces/$NAMESPACE/deploymentconfigs/$DEPLOYMENTCONFIG/ \
 -k --cacert "$SECRET_CA_FILE" \
 -H "Authorization: Bearer $(<$SECRET_TOKEN_FILE)" \
 -H "Content-Type: application/strategic-merge-patch+json" \
 -X PATCH \
 -d "{\"spec\":{\"replicas\":$REPLICAS}}"
