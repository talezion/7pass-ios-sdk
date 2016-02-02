# 7pass-ios-sdk

7Pass iOS SDK is a Swift library for interacting with the
[7Pass SSO service](https://7pass.de). You can use this library to
implement authentication for your app and take advantage of the
already existing features that 7Pass SSO offers.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

SevenPass is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SevenPass', :git => 'https://github.com/p7s1-ctf/7pass-ios-sdk.git'
```

## Running the sample application

To demonstrate the functionality of the library, there's a sample
application available. The application is configured to run against
the QA instance of 7Pass and uses test credentials
(Example/SevenPass/SsoManager.swift). Feel free to use these credentials
while testing but you need to obtain real credentials before releasing
your app.

To obtain the real credentials, you first need to contact the 7Pass
Tech Team.

Once you have the credentials available, you can go ahead and type

```
pod install
```

in `Example` directory, open `SevenPass.xcworkspace` project in XCode,
select `SevenPass-Example` build configuration and run it.

The sample application should now start within the configured device
(or the emulator) and should provide several tabs each implementing a
feature you might want to use in your app.

## Usage

You are strongly encouraged to go over the sample application to see
how the API should be used.

If you're starting the development, it's always a good idea to work
against a non live instance of the 7Pass SSO service. In this case,
we'll use the QA environment. Don't forget to switch to the production
one before you release your application to the public.

First, let's initialize the library with sample configuration:

```swift
let configuration = SevenPassConfiguration(
    consumerKey: "56a0982fcd8fb606d000b233",
    consumerSecret: "2e7b77f99be28d80a60e9a2d2c664835ef2e02c05bf929f60450c87c15a59992",
    callbackUri: "oauthtest://oauth-callback",
    environment: "qa"
)

let sso = SevenPass(configuration: configuration)
```

## Authentication flow

The library offers several ways of logging in the user. The result of
every login is eventually an instance of `TokenSet`. A `TokenSet`
represents the three different token types the server will return:

1. *Access token* - This token proofs the identity of the user and is
thus included in almost every remote call the library
performs. Every access token is valid just for 2 hours. In cannot
be used after that.

2. *Refresh token* - This token can be used to get a new `TokenSet`
with a fresh access token. Its expiration time is set to 90 days
and its prolonged every time you use it. If however the token
expired, you need to ask the user to login again.

3. *ID token* - This token contains information (claims) about the
logged in user. You can for example get the user's ID, name, email
etc.

You don't generally need to worry about the current `TokenSet` and how
it's used but you need to make sure it's valid before use:

```swift
sso.authorize(
    scopes: ["openid", "profile", "email"],
    success: { tokenSet in
        // tokenSet.accessToken?.isExpired()
        // tokenSet.refreshToken?.isExpired()
    },
    failure: { error in
        print(error.localizedDescription)
    }
)
```

If that access token is fresh, you can use the token set to perform API
calls. After that, you can use that TokenSet to initialize an API client:

```swift
let accountClient = sso.accountClient(tokenSet)
```

Otherwise, you need to refresh it, using a refresh token.

```swift
let refreshTokenString = tokenSet.refreshToken!.token

sso.authorize(refreshToken: refreshTokenString,
    success: { tokenSet in
        // Do some stuff
    },
    failure: errorHandler
)
```

Of course, you need to make sure that the refresh token itself is
fresh. If it's not, you cannot get a fresh access token and need to
ask the user to log in again. If you're using the Web view flow and
the user has an active session on 7Pass, chances are he/she will come
back immediately without having to fill in the credentials.

Since the same token set can be used in the span of multiple days, you
should store it instead of forcing the user to re-login every
time. There's a utility class you can use to save the token set
into the keychain.

```swift
let tokenSetCache = SevenPassTokenSetCache(configuration: sso.configuration)

// Load token set from a keychain
let tokenSet = tokenSetCache.load()

// Store token set in the keychain
tokenSetCache.tokenSet = tokenSet
tokenSetCache.save()

// Delete token set
tokenSetCache.delete()
```

### 1. Logging in using Web view

The most basic way of logging in the user is using the Web view.

```swift
sso.authorize(
    scopes: ["openid", "profile", "email"],
    success: { tokenSet in
        // Do some stuff
    },
    failure: errorHandler
)
```

The code will open the provided Web view which will navigate to the
7Pass's login dialog. From there, the user has several options, he/she
can use his/her credentials directly or use Google/Facebook.

Once the process is done, the web view will automatically close and
the result will be provided in the callback.

Once the process is successfully finished, we can use the obtained
`tokenSet` to instantiate API client.

### 2. Logging in using login and password

In case you want to provide more native experience for the user, the
library offers logging in using the user's 7Pass login and
password (grant_type = password). This way, you get to design the login
form yourself using the iOS widgets.

```swift
sso.authorize(
    login: login.text!,
    password: password.text!,
    scopes: ["openid", "profile", "email"],
    success: { tokenSet in
        // Do some stuff
    },
    failure: errorHandler
)
```

### 3. Logging in using social

In situations when the user is already logged in using some other
service (currently supported services are Facebook or Google), you can
use the `social` flow.

In this flow, you provide an access token you've received from the other service
and 7Pass will make sure to create a new 7Pass account (with all of the user
details) or identify an existing 7Pass account.

```swift
sso.authorize(
    providerName: "facebook",
    accessToken: "foobarbaz",
    scopes: ["openid", "profile", "email"],
    success: { tokenSet in
        // Do some stuff
    },
    failure: errorHandler
)
```

### 4. Autologin

In case, that you already have valid `TokenSet` (fe. from password or social login) or a valid `autologin_token` and you want to create user session in the WebView, you can utilize `autologin` method.

By default this method sets `response_type = "none"`

### 5. Logging out

In the app's perspective, a user is logged in when you have a fresh
`TokenSet`. In order to log the user out, all that's required is to
"forget" the tokens. Optionally, you can destroy the user's session in WebView as well.

To use it, just call

```swift
sso.destroyWebviewSession(failure: errorHandler)
```

### Handling interaction_required error

It's important to note that if the user hasn't accepted all of the necessary consents for the client or the service the client belongs to, the login through Username & Password or Social method might fail and it's necessary to handle this situation in your error handling callback.

```swift
func errorHandler(error: NSError) {
    // Let autologin handle interaction_required errors
    if let errorMessage = error.userInfo["error"] as? String where errorMessage == "interaction_required" {
        let autologinToken = error.userInfo["autologin_token"] as! String

        self.sso.autologin(
            autologinToken: autologinToken,
            scopes: ["openid", "profile", "email"],
            params: ["response_type": "id_token+token"],
            success: { tokenSet in
                // Do some stuff
            },
            failure: errorHandler
        )
    }

    // Handle other errors
}
```

##### Login using valid tokenSet

TokenSet has to include valid `access_token` and `id_token`

```swift
sso.autologin(tokenSet,
    scopes: ["openid", "profile", "email"],
    rememberMe: false,
    success: { tokenSet in
        // Do some stuff
    },
    failure: errorHandler
)
```

##### Login using autologin token

Used for example when `interaction_required` error is returned from the server.

```swift
sso.autologin(
    autologinToken: "AUTOLOGINTOKEN",
    scopes: ["openid", "profile", "email"],
    params: ["response_type": "id_token+token"],
    success: { tokenSet in
        // Do some stuff
    },
    failure: errorHandler
)
```

## Account client

Now that you have an account's `TokenSet`, you can already identify the user and
proceed to your actual app. You can, however, request further details about the
user. Each method call corresponds to an endpoint available on 7Pass, you're
encouraged to go through the
[documentation](http://guide.docs.7pass.ctf.prosiebensat1.com/api/index.html?focusTabs=node#api-Accounts).

```swift
let accountClient = sso.accountClient(tokenSet)
```

### Getting the account's details

The simplest remote call you can make is to request [the account's
details](http://guide.docs.7pass.ctf.prosiebensat1.com/api/index.html?focusTabs=node#api-Accounts-GetAccount).

```swift
accountClient.get("me",
    success: { json, response in
        print(json)
    },
    failure: errorHandler
)
```

Note that you might not need to request the additional user details as the most
basic ones are already present in the ID Token as part of the `TokenSet`. It
generally depends on your app's requirements.

```swift
tokenSet.idTokenDecoded
```

### Refreshing accountClient TokenSet

Account client is an instance of `SevenPassRefreshingClient` which handles refreshing of the tokens for you seamlessly.

## Credentials client

A credentials client can be used to perform various administrative tasks not
bound to a particular account. For example, you can verify whether an email
address is unused or whether a password is of sufficient quality and others.
Getting this kind of client doesn't require any interaction from the user, it's
issued based on your client's credentials.

Same as with the Account client you will receive a valid `TokenSet`, however,
the token set will not contain anything but an access token and its validity
will be limited to just 15 minutes. Since the token set doesn't have a Refresh
token, it's necessary to request a new one after the 15 minutes have passed if
required.

```swift
sso.authorize(
    parameters: [
        "grant_type": "client_credentials",
    ],
    success: { tokenSet in
        // Do some stuff
    },
    failure: errorHandler
)
```

Once you have the token set available, you can get the Credentials client and
invoke the available methods.

```swift
let deviceClient = sso.deviceCredentialsClient(tokenSet)
```

### Checking an email's availability

Validates the provided email address and returns whether it's available for use.
You can use this method to give immediate feedback to users (i.e. during a
registration process). See more information in [the
documentation](http://guide.docs.7pass.ctf.prosiebensat1.com/api/#api-Emails-ActionCheckMail).

```swift
deviceClient.post("checkMail",
    parameters: [
        "email": login.text!,
        "flags": [
            "client_id": sso.configuration.consumerKey
        ]
    ],
    success: { json, response in
        if let error = json["data"]?["error"] as? String {
           // E-Mail is invalid
        }
    },
    failure: errorHandler
)
```

The response also contains a suggested email address so that you can easily
provide the "did you mean x?" functionality in case the user has made a typo in
the address.

### Checking a password's validity

As a next step in a registration form you might want to provide a feedback
regarding the validity of the provided password. You can find all of the
requirements and the response codes in [the
documentation](http://guide.docs.7pass.ctf.prosiebensat1.com/api/#api-Accounts-ActionCheckPassword).

```swift
deviceClient.post("checkPassword",
    parameters: [
        "password": password.text!
    ],
    success: { json, response in
        if let errors = json["data"]?["errors"] as? [String] {
            // Password is not valid, got array of errors
        }
    },
    failure: errorHandler
)
```

### Creating a new account

Finally, you can create a brand you account directly. The only mandatory
parameter is a valid email address and a password. If you don't want to force
your users to type in the password, you can request an auto generated password
(in which case only the email address is required).

```swift
deviceClient.post("registration",
    parameters: [
        "email": login.text!,
        "password": password.text!,
        "flags": [
            "client": [
                "id": sso.configuration.consumerKey, // Associate with a service
                "agb": true, // Accept ToS consents (user should given permissions beforehand)
                "dsb": true, // Accept privacy policy consents (user should given permissions beforehand)
                "implicit": true // Accept implicit optins
            ]
        ]
    ],
    success: { json, response in
        // Account creation status returned in json constant
    },
    failure: errorHandler
)
```

## Advanced usage

### Customize WebView

Create your own custom class implemeting `SevenPassURLHandlerType` protocol and pass that instance to `SevenPass` init.

```swift
let sso = SevenPass(configuration: configuration, urlHandler: YourWebViewController())
```

## License

SevenPass is available under the MIT license. See the LICENSE file for more info.
