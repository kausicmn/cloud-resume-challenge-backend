import json
import boto3
client = boto3.client('dynamodb')
def lambda_handler(event, context,client=client):
    # TODO implement
    table_name = 'mycloudtable'      
    get_response = client.get_item(
    Key={
        'Id': {
            'S': 'cnt',
        },
    },
    TableName=table_name,
)
    views=int(get_response['Item']['value']['N'])
    views=views+1
    put_response = client.put_item(
    Item={
        'Id': {
            'S': 'cnt',
        },
        'value': {
            'N': str(views)
        },
    },
    TableName=table_name
)
    return {
        'statusCode': 200,
        'body': views
    }
