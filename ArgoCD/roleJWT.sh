PROJ=myproject
APP=guestbook-default
ROLE=get-role
argocd proj role create $PROJ $ROLE
argocd proj role create-token $PROJ $ROLE -e 10m
JWT=<value from command above>
argocd proj role list $PROJ
argocd proj role get $PROJ $ROLE


# Add policy for the role
argocd proj role add-policy $PROJ $ROLE \
    --action get --permission allow \
    --object $APP
argocd app get $APP --auth-token $JWT

# Remove prev policy and add new policy: wildcard
argocd proj role remove-policy $PROJ $ROLE -a get -o $APP
argocd proj role add-policy $PROJ $ROLE -a get \
    --permission allow -o '*'

argocd app get $APP --auth-token $JWT
argocd proj role get $PROJ $ROLE

argocd proj role get $PROJ $ROLE
# Revoke tk
argocd proj role delete-token $PROJ $ROLE <id field from the last command>