from telethon.sync import TelegramClient
from telethon.tl.functions.messages import ImportChatInviteRequest  # Add this import
import json5

# Load configuration from user.json5
with open('user.json5', 'r') as f:
    config = json5.load(f)

api_id = config['api_id']
api_hash = config['api_hash']
phone = config['phone']

# Use the invite link for Tradeando.net
invite_link = "https://t.me/+ZoZ5yhxs5643OTlk"

# Initialize client
client = TelegramClient('session_name', api_id, api_hash)

async def get_channel_info():
    try:
        await client.start(phone=phone)
        # Extract the invite hash (part after t.me/)
        invite_hash = invite_link.split('/')[-1].lstrip('+')
        # Join the channel using the invite link
        result = await client(ImportChatInviteRequest(hash=invite_hash))
        entity = result.chats[0]  # Get the channel entity
        # Extract details
        title = entity.title
        username = f"@{entity.username}" if entity.username else "No username (private channel)"
        channel_id = f"-100{entity.id}"
        print(f"Channel Title: {title}")
        print(f"Channel Username: {username}")
        print(f"Channel ID: {channel_id}")
        # Verify by fetching one message
        async for message in client.iter_messages(entity, limit=1):
            print(f"Verification: Recent message ID {message.id} from {title}")
    except Exception as e:
        print(f"Error: {e}")

with client:
    client.loop.run_until_complete(get_channel_info())