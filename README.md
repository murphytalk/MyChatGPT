# MyChatGPT

A ChatGPT UI for desktop, mobile and web, thanks to Flutter.

## Build

Put a `.env` file in the project root directory, put your OpenAI API key and MongoDb connecting string in the file. For example:

```
OPENAI_API_KEY=sk-Your-OpenAI-API-KEY
MONOGDB_CONN_STR=mongodb+srv://username:password@your-mongodb-server/db-name
```

Then run `flutter pub run build_runner build` to generate `lib/env/env.g.dart`.

DO NOT share your the `.env` and `env.g.dart` file. They have already been added to `.gitignore`.

### Prepare data in MongoDb

Prompts to AI and conversation history are managed on user/owner/profile basis.

In your MongoDb , populate a document like below in collection `settings` before start the app.

```json
{
    "name":"users",
    "users":{
        "profile1": {"name":"User1"},
        "profile2": {"name":"User2"}
    }
}
```
