set -x
# https://developer.github.com/v3/repos/commits/#list-pull-requests-associated-with-commit
number=`curl -H "Accept: application/vnd.github.groot-preview+json" https://api.github.com/repos/UKGovernmentBEIS/beis-opss-psd/commits/$TRAVIS_COMMIT/pulls | jq '.[0] | .number'`

./infrastructure/ci/install-cf.sh
cf login -a api.london.cloud.service.gov.uk -u $CF_USERNAME -p $CF_PASSWORD -o 'beis-opss' -s $SPACE
cf delete -f psd-pr-$number-web
cf delete -f psd-pr-$number-worker
cf logout
