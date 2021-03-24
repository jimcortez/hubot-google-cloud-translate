# hubot-google-cloud-translate

Let hubot do translations using google cloud translate

All languages supported by google cloud translate should work.

WARNING: This is a fun project hacked together, there are no tests, enjoy!

## Installation

In hubot project repo, run:

`npm install hubot-google-cloud-translate --save`

Then add **hubot-google-cloud-translate** to your `external-scripts.json`:

```json
[
  "hubot-google-cloud-translate"
]
```

### Google Cloud setup
Warning: This module will not work unless you set up an google cloud account and activate the translate api. There is no sample key.

Follow the instructions here to configure your google cloud account https://cloud.google.com/translate/docs/setup#project

This library uses Google's provided nodejs SDK, which looks for the project credentials file path in the `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

## Sample Interaction

```
user> hubot translate to afrikaans please make me a sandwich
hubot> English "please make me a sandwich" translates as "maak vir my 'n toebroodjie asb." in Afrikaans
user> hubot translate Donde está la biblioteca
hubot> "Donde está la biblioteca" is Spanish for "Where is the library"
user> hubot translate 圖書館在哪裡
hubot> "圖書館在哪裡" is Chinese (Traditional) for "Where is the library"
```

## Special Thanks

A Special thanks to the contributors of https://github.com/hubot-scripts/hubot-google-translate

This code is influenced by them, but has been re-written completely.
