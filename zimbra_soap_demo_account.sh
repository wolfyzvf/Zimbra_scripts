#!/bin/bash
############################################################
# AUTHOR: Wolfyxzvf
# DESCRIPTION: Create demo account in Zimbra using SOAP
# CREATED: 11/11/2017
# VERSION: 1.0
############################################################

usage ()
{
echo " This script will create zimbra demo accounts using SOAP
	-a: Zimbra administrator
	-s: Zimbra server
	-u: User pattern to create
	-d: Domain of the created users
	-c: How many ?

Example : The following example will create 400 demo accounts :
	zimbra_soap_demo_account.sh -a wolfyxzvf -s myzimbra.domain.tld -u Demo -d demodomain.tld -c 400
	"
}

### Getting the Admin Token; mandatory to make admin tasks
get_admin_token ()
{
	# Checking before if token is already there
if [ -z "$COOKIE_ZM_ADMIN_AUTH_TOKEN" ]; then
		### Asking for the admin password
		echo "Enter Zimbra Admin Password"
		read -s ZIMBRA_PASSWORD

		### Creating the SOAP Request
	SOAP_REQUEST_ADMIN="$(cat <<EOF
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Header>
    <context xmlns="urn:zimbra">
      <authToken/>
      <nosession/>
      <userAgent name="Jmeter" version="1.44" />
    </context>
  </soap:Header>
  <soap:Body>
    <AuthRequest xmlns="urn:zimbraAdmin">
      <name>${ZIMBRA_ADMIN}</name>
      <password>${ZIMBRA_PASSWORD}</password>
    </AuthRequest>
  </soap:Body>
</soap:Envelope>
EOF
	)"
	COOKIE_ZM_ADMIN_AUTH_TOKEN=`curl -k -s -X POST -H 'Content-type: text/xml' --data-binary  "$SOAP_REQUEST_ADMIN" $URL | sed -n 's:.*<authToken>\(.*\)</authToken>.*:\1:p'`

	### Go to the creation account function
	create_accounts
	fi
}

### Create the accounts with the admin token
create_accounts()
{

### We make a loop with the number of users you want to create
COUNTER=0
while [ $COUNTER -lt $USER_NUMBER_COUNTER ]; do
SOAP_CREATE_ACCOUNTS="$(cat <<EOF
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Header>
    <context xmlns="urn:zimbra">
      <userAgent name="Jmeter" version="1.44" />
      <nonotify />
      <noqualify />
      <authToken>$COOKIE_ZM_ADMIN_AUTH_TOKEN</authToken>
    </context>
  </soap:Header>
  <soap:Body>
    <CreateAccountRequest name="${USER_PATERN_PREFIX}${COUNTER}@${SMTP_DOMAIN}" xmlns="urn:zimbraAdmin"/>
  </soap:Body>
</soap:Envelope>
EOF
)"

	echo "Creating Account ${USER_PATERN_PREFIX}${COUNTER}@${SMTP_DOMAIN}"
	curl -s -k -X POST -H 'Content-type: text/xml' --data-binary  "$SOAP_CREATE_ACCOUNTS" --output /dev/null $URL
	let COUNTER=COUNTER+1
done

#### Reseting vars
ZIMBRA_ADMIN=""
ZIMBRA_PASSWORD=""
SOAP_REQUEST_ADMIN=""
COOKIE_ZM_ADMIN_AUTH_TOKEN=""
USER_PATERN_PREFIX=""
USER_NUMBER_COUNTER=""
SMTP_DOMAIN=""
URL=""

}

options=':a:s:u:c:d:'
while getopts $options opt; do
  case $opt in
    a)
      ZIMBRA_ADMIN="$OPTARG" >&2
      ;;
    s)
      ADMIN_URL="$OPTARG" >&2
      URL="https://$ADMIN_URL:7071/service/admin/soap"
      ;;
    u)
      USER_PATERN_PREFIX="$OPTARG" >&2
      ;;
    c)
      USER_NUMBER_COUNTER="$OPTARG" >&2
      ;;
    d)
      SMTP_DOMAIN=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
    *) echo "Unimplemented option: -$OPTARG" >&2;
       exit 1
       ;;
  esac
done

# Checking everything is set
if [[ -z "$ZIMBRA_ADMIN" || -z "$URL" || -z "$USER_PATERN_PREFIX" || -z "$USER_NUMBER_COUNTER" || -z "$SMTP_DOMAIN" ]];
then
    echo "missing a required parameter (every options is requied)"
    usage
else
    get_admin_token
fi
