# SwiftyGiphy

SwiftyGiphy is a library to allow you to easily integrate Giphy image search into your app.

### The library consists of 2 primary components

1. **SwiftyGiphyViewController**, which provides a simple UI for search, and callbacks for selected images so you can quickly integrate Giphy in to your app. The controller also supports paging so your users can contiously scroll and see results.

2. **SwiftyGiphyAPI**, which provides an API layer to access Giphy. This does not require you to use SwiftyGiphyViewController for your UI, and can be used standalone.

<img src="https://github.com/52inc/SwiftyGiphy/blob/master/Screenshots/TrendingScreenshot.png?raw=true" width=320/>
<br/>
<br/>
<img src="https://github.com/52inc/SwiftyGiphy/blob/master/Screenshots/SearchScreenshot.png?raw=true" width=320/>

## Installing
SwiftyGiphy supports Cocoapods and manual includes.

#### Cocoapods
`pod 'SwiftyGiphy', '~> 1.0'`

#### Manual Include
Add the files in the Library and Assets folder to your project. You'll also need to include the dependencies:

* [ObjectMapper](https://github.com/Hearst-DD/ObjectMapper) - v2.2
* [SDWebImage/GIF](https://github.com/rs/SDWebImage)
* [NSTimer-Blocks](https://github.com/jivadevoe/NSTimer-Blocks)
* [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) - v1.0

#### Carthage / Swift Package Manager
Carthage and Swift Package Manager are not currently supported. But, if you'd like to create a pull request with support for either of these I'd be happy to consider including it.

## Usage

### Setup
You'll need to configure SwiftyGiphy with your Giphy API key. We recommend you do this in your AppDelegate's -didFinishLaunching method.

`SwiftyGiphyAPI.shared.apiKey = "my_api_key"`

**Note:** _For testing, you can use the Giphy public beta key. However, you **MUST** change it before releasing your app._

`SwiftyGiphyAPI.shared.apiKey = SwiftyGiphyAPI.publicBetaKey`

### Recommendations
Recommended usage is to present SwiftyGiphyViewController modally in a UINavigationController, with another object (such as the presenting view controller) assigned as the delegate of SwiftyGiphyViewController.

You should dismiss SwiftyGiphyViewController in the delegate methods, when you need to.

**IMPORTANT:** SwiftyGiphyViewController will not dismiss itself. Similar to UIImagePickerController, you'll need to dismiss it from a delegate callback when you want it to go away.

## Components
SwiftyGiphy provides a few useful things for your Giphy integration:

* **SwiftyGiphyViewController** (outlined above) gives you an easy to use UI for interacting with Giphy image search.
* **SwiftyGiphyViewControllerDelegate** is called by SwiftyGiphyViewController to notify you when the user selects GIFs, or is ready to close the screen.
* **SwiftyGiphyAPI** provides easy access to the Giphy API. Currently this supports all of the Giphy API [documented here](https://github.com/Giphy/GiphyAPI), with the exception of image uploads.
* **SwiftyGiphy Data Models** are provided by the API layer so you can interact with real objects instead of dictionaries and arrays.

## Questions
If you have questions on how to integrate SwiftyGiphy into your project, feel free to create an issue and we'll try to help the best we can. Please note that we'll only be able to provide assistance for SwiftyGiphy in its 'stock' form, and we won't assist with problems you have due to custom modifications.

Pull requests are encouraged, especially if you feel like assisting in more full implementing the Giphy API layer.

## Apps using SwiftyGiphy
If you have an app using SwiftyGiphy, let me know and I'll link to it here.