from pyrogram import Client

api_id = 12345678
api_hash = 'your_api_hash_here'
phone = '+1234567890'
channel = '@your_channel_username'

app = Client("my_account", api_id=api_id, api_hash=api_hash)

async def main():
    async with app:
        await app.start()  # Authenticates similarly
        async for message in app.get_chat_history(channel, limit=10):
            print(f"Message ID: {message.id}")
            print(f"Date: {message.date}")
            print(f"Text: {message.text}\n" if message.text else "No text\n")

app.run(main())