# ZeroModel

**Zero model files. Zero manual mapping. Zero crashes.**

ZeroModel is a dynamic API response modeling library for iOS.  
No model files. No manual property declaration. No crashes when backend changes datatypes.

---

## The Problem

Every iOS developer writes this kind of boilerplate:

```swift
struct LoginResponse: Codable {
    let userId: Int
    let email: String
    let phone: String
    // ...10 more properties
}
```

Then backend changes `userId` from `Int` to `String` — **app crashes**.  
Then a new API comes in — **write another model file**.  
Then nested objects — **write more files**.

---

## The ZeroModel Solution

```swift
// AppDelegate
ZeroModel.configure()

// API call — model maps itself automatically
ZeroModel.shared.loginModel.map(from: response)

// Use anywhere — zero crashes, zero model files
userIdLabel.text   = ZeroModel.shared.loginModel.userId.string
emailLabel.text    = ZeroModel.shared.loginModel.email.string
let amount         = ZeroModel.shared.loginModel.totalAmount.double

// Nested — any depth
let city           = ZeroModel.shared.loginModel.data.order.customer.address.city.string

// Arrays
let productName    = ZeroModel.shared.loginModel.items[0].productName.string
```

---

## Features

- ✅ **Zero model files** — no structs, no Codable, no manual property declaration
- ✅ **Auto-mapping** — pass any JSON dictionary, properties create themselves
- ✅ **Crash-safe types** — backend changes Int → String? ZeroModel handles it silently
- ✅ **Infinite nesting** — nested dicts and arrays work at any depth
- ✅ **Auto-cache** — values persist until the next API call updates them
- ✅ **snake_case auto-convert** — `user_id` becomes `.userId` automatically

---

## Installation

### CocoaPods
```ruby
pod 'ZeroModel', '~> 1.0'
```

### Swift Package Manager
```swift
.package(url: "https://github.com/YOUR_USERNAME/ZeroModel.git", from: "1.0.0")
```

---

## Usage

### 1. Configure once in AppDelegate

```swift
import ZeroModel

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: ...) -> Bool {
    ZeroModel.configure()
    return true
}
```

### 2. Map API response

```swift
// In your network call completion
ZeroModel.shared.loginModel.map(from: jsonDictionary)
```

### 3. Access properties anywhere

```swift
// Strings
let email = ZeroModel.shared.loginModel.email.string

// Numbers
let age   = ZeroModel.shared.loginModel.age.int
let price = ZeroModel.shared.loginModel.price.double

// Nested
let city  = ZeroModel.shared.loginModel.address.city.string

// Arrays
let name  = ZeroModel.shared.loginModel.items[0].name.string

// Null safe
if ZeroModel.shared.loginModel.discount.isNull {
    // handle null
}
```

### 4. Type safety — no crashes

```swift
// Backend sends userId as Int
// Later backend changes to String
// ZeroModel handles BOTH automatically — zero code change needed

userIdLabel.text = ZeroModel.shared.loginModel.userId.string  // always works
```

---

## Cache

Values are automatically cached and persist until the same model is updated by a new API call.

```swift
// Clear a specific model
ZeroModel.shared.clear("loginModel")

// Clear all models
ZeroModel.shared.clearAll()
```

---

## Requirements

- iOS 13.0+
- Swift 5.5+
- Xcode 13+

---

## License

ZeroModel is available under the MIT license. See the LICENSE file for more info.
