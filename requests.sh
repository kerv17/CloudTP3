source Terraform/ips.sh
curl -X GET http://$GATEKEEPER_DNS/health_check
echo "Running requests"
# Create empty files for the logs
touch direct.log
touch random.log
touch customized.log

for ((i=1; i<=25; i++))
do
    { time curl -X POST -H "Content-Type: application/json" -d '{"sql": "INSERT INTO direct_table (id, request_time) VALUES(DEFAULT,DEFAULT)"}' http://$GATEKEEPER_DNS/direct; } 2>&1 | grep real >> direct.log
    { time curl -X POST -H "Content-Type: application/json" -d '{"sql": "INSERT INTO random_table (id, request_time) VALUES(DEFAULT,DEFAULT)"}' http://$GATEKEEPER_DNS/random; } 2>&1 | grep real >> random.log
    { time curl -X POST -H "Content-Type: application/json" -d '{"sql": "INSERT INTO customized_table (id, request_time) VALUES(DEFAULT,DEFAULT)"}' http://$GATEKEEPER_DNS/customized; } 2>&1 | grep real >> customized.log
done
