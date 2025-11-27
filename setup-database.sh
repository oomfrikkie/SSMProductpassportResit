# Wait for Dgraph to be ready...

until curl -f http://ppt_db1:8080/health; do 
  sleep 2
done

# Loads in the predefined schema
curl -X POST ppt_db1:8080/admin/schema --data-binary '@/data/schema/schema.graphql'

# Loads in the predefined data
curl -X POST ppt_db1:8080/mutate?commitNow=true -H "Content-Type: application/json" -d @/data/import/data.json