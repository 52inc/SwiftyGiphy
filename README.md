#SwiftyGiphy
SwiftyGiphy is a library to allow you to easily integrate Giphy image search into your app.

The library includes a view controller you can present that shows trending giphy images, and allows search. The controller also supports paging so your users can contiously scroll and see results.

The SwiftyGiphy view controller provides a delegate hook so you can be notified of what gif a user has selected.

<img src="https://github.com/52inc/SwiftyGiphy/blob/master/Screenshots/TrendingScreenshot.png?raw=true" width=320/>
<br/>
<br/>
<img src="https://github.com/52inc/SwiftyGiphy/blob/master/Screenshots/SearchScreenshot.png?raw=true" width=320/>

##Installing
SwiftyGiphy supports Cocoapods and manual includes.

####Cocoapods
`pod 'SwiftyGiphy', '~> 1.0'`

####Manual Include
Add the files in the Library and Assets folder to your project.

##Usage

###Setup
You'll need to configure SwiftyGiphy with your Giphy API key. We recommend you do this in your AppDelegate's -didFinishLaunching method.

`SwiftyGiphyAPI.shared.apiKey = "my_api_key"`

**Note:** _For testing, you can use the Giphy public beta key. However, you **MUST** change it before releasing your app._

`SwiftyGiphyAPI.shared.apiKey = SwiftyGiphyAPI.publicBetaKey`

###Recommendations
Recommended usage is to present SwiftyGiphyViewController modally, with another object (such as the presenting view controller) assigned as the delegate of SwiftyGiphyViewController.

You should dismiss SwiftyGiphyViewController in the delegate methods, when you need to.

**IMPORTANT:** SwiftyGiphyViewController will not dismiss itself. Similar UIImagePickerController, you'll need to dismiss it from a delegate callback when you want it to go away.

##Components
SwiftyGiphy provides a few useful things for your Giphy integration:

* **SwiftyGiphyViewController** (outlined above) gives you an easy to use UI for interacting with Giphy image search.
* **SwiftyGiphyViewControllerDelegate** is called by SwiftyGiphyViewController to notify you when the user selects GIFs, or is ready to close the screen.
* **SwiftyGiphyAPI** provides easy access to the Giphy API. Currently the search and trending endpoints are implemented. Hint: I'd welcome pull requests with this component more fleshed out.
* **SwiftyGiphy Data Models** are provided by the API layer so you can interact with real objects instead of dictionaries and arrays.