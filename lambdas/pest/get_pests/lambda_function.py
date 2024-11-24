# lambda function that retrieves (all) data from dynamodb table pest_reports in us east 1

import json
import boto3

def lambda_handler(event, context):
    # Initialize a session using Amazon DynamoDB
    dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
    
    # Select your DynamoDB table
    table = dynamodb.Table('pest_reports')
    
    # Scan the table to get all items
    response = table.scan()
    
    # Get the items from the response
    items = response['Items']
    
    # Format the items
    formatted_items = []
    for item in items:
        lat, lon = map(float, item['geoJson'].split(','))
        formatted_item = {
            'country': item['country'],
            'region': item['region'],
            'date': item['date'],
            'pest': item['pest'],
            'description': item['description'],
            'lat': lat,
            'lon': lon
        }
        formatted_items.append(formatted_item)
    
    # Return the formatted items in JSON format with CORS headers
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps({'pests': formatted_items})
    }


# if __name__ == '__main__':
#     # Mock event and context
#     event = {}
#     context = {}

#     # Call the lambda_handler function
#     response = lambda_handler(event, context)

#     # Print the response
#     print("Response:", response)