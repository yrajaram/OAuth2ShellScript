#!/bin/sh
##
# Shell script to invoke OAuth 2.0 protected service/API using client credentials grant type
#
# Usage: Invoke with parameter "-f" to create a new AuthCode
#         if not, previously generated Auth Code will be used
# Note: Only client credentials grant type is supported in this shell script
##

#------------change these values
tokenUrl=https://token.url/for/oauth2/token
clientId=ClientID
clientSecret=Secret
serviceUrl="https://your.service.url/here"
format="application/json"
#-------------end changes

grantType=client_credentials
tmpFile=/tmp/oauth2-request-$$.xml
datFile=.oauth2.dat

touch ${datFile}

while getopts "fo:" opt; do
     case $opt in
         f)
                # Force generate auth code
        echo "Calling to generate access token"
curl  -s -H 'Content-Type: application/x-www-form-urlencoded'  "${tokenUrl}" -X POST -d "client_id=${clientId}" -d "client_secret=${clientSecret}" -d "grant_type=${grantType}"  -o ${tmpFile}
authCode=`cat ${tmpFile}|tail -1|awk -F: '{print $4}'|awk -F\" '{print $2}'`
echo ${authCode} > ${datFile}
if [ "${authCode}" = "" ] ; then
echo "Unable to generate access token due to:"
cat ${tmpFile}
exit -1
fi
                ;;
         o)
                # Specify the output format for response from the service/API
                echo ${OPTARG}
                case ${OPTARG} in
                json) ;;
                xml)
                        format="application/xml"
                        ;;
                txt)
                        format="text/plain"
                        ;;
                html)
                        format="text/html"
                        ;;
                *)
                        echo "Unsupported format. Will fetch json response."
                        ;;
                esac
                ;;
         ?)
                # Show help
                echo "Usage: `basename $0` options [-f] [-o format] url"
                echo " f - force new auth code generation"
                echo " o - response format  (json/xml)"
                exit -2;
                ;;
     esac
done

origParams=$@
shift $((OPTIND-1))
if [ "$*" != "" ]; then
toUrl=$*
fi

authCode=`cat ${datFile}`
echo "Using access token: ${authCode}"
read -p "Enter to continue..."

echo "Submitting request to :" ${toUrl}
echo "Response:"
curl -s -k -H Accept:${format} -H "Authorization: Bearer ${authCode}" -X GET  ${toUrl} -o ${tmpFile}
cat ${tmpFile}

grep 'Not Authorized' ${tmpFile}
if [ $? -eq 0 ]; then
        read -p  "Authorization has expired. Do you want to run again after creating new auth? [Y/n]" ans
else
        ans=n
fi
rm -f ${tmpFile}

case ${ans:=Y} in
Y|y)
        echo "Running"
        $0 -f ${origParams}
        ;;
esac
echo ""