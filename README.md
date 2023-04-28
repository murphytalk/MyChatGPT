# MyChatGPT

A ChatGPT UI for desktop, mobile, and web.

All conversations are saved in MongoDB, [MongoDb Atlas](https://www.mongodb.com/atlas) offers a free tier, which is more than sufficient for this app.

## Build

Put a `.env` file in the project root directory, put your OpenAI API key and MongoDb connecting string in the file. For example:

```
OPENAI_API_KEY=sk-Your-OpenAI-API-KEY
MONOGDB_CONN_STR=mongodb+srv://username:password@your-mongodb-server/db-name
```

Then run `flutter pub run build_runner build` to generate `lib/env/env.g.dart`.

DO NOT share your the `.env` and `env.g.dart` file. They have already been added to `.gitignore`.

