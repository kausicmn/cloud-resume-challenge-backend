import boto3
import unittest
# from lambda_function import lambda_handler
from moto import mock_dynamodb 
client = boto3.client('dynamodb',region_name='us-east-1')  
def lambda_handler(event, context,client=client):
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
class TestLambda(unittest.TestCase):
    @mock_dynamodb
    def test_count(self):
    # Create a mock DynamoDB client
        dynamodb_client = boto3.client('dynamodb', region_name='us-east-1')
    # Create a mock DynamoDB table
        table_name = 'mycloudtable'
        dynamodb_client.create_table(
        TableName=table_name,
        AttributeDefinitions=[
            {
                'AttributeName': 'Id',
                'AttributeType': 'S'
            },
        ],
        KeySchema=[
            {
                'AttributeName': 'Id',
                'KeyType': 'HASH'
            },
        ],
        ProvisionedThroughput={
            'ReadCapacityUnits': 5,
            'WriteCapacityUnits': 5
        }
    )
    # Put an item into the table
        item = {
        'Id': {'S': 'cnt'},
        'value': {'N': '5'}
        }
        dynamodb_client.put_item(
        TableName=table_name,
        Item=item
        )
        # table=Mock()
        # table.get_item.return_value = {'Item': {'Id': {'S': 'cnt'}, 'value':{'N': 5} } }
        result = lambda_handler(event={}, context={}, client=dynamodb_client)
        self.assertEqual(result, {
            'statusCode':200,
            'body': 6
        })

if __name__ == '__main__':
    unittest.main()


        




