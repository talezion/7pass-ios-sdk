import OAuthSwift
import WebKit

typealias WebView = WKWebView

class SevenPassWebViewController: OAuthWebViewController, WKNavigationDelegate {
    var targetURL: NSURL = NSURL()
    var webView: WebView = WebView()
    var toolbar: UIToolbar!
    var dismissUrl: NSURL?
    
    convenience init(urlString: String) {
        self.init()
        
        dismissUrl = NSURL(string: urlString)
    }
    
    @IBAction func close(sender: UIBarButtonItem) {
        dismissWebViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 42, 0 ); // Add padding for the top bar at the bottom
        
        view.addSubview(webView)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "close:")
        
        toolbar = UIToolbar()
        toolbar.items = [doneButton]
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(toolbar)

        // WebView & Toolbar to 100% width
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[webView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["webView": webView]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[toolbar]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["toolbar": toolbar]))
        
        // WebView to 100% height
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[webView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil,
            views: [
                "webView": webView
            ]))
      
        // Align toolbar to the bottom, on top of the WebView
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[toolbar]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil,
            views: [
                "toolbar" :toolbar
            ]))
        
        loadAddressURL()
    }
    
    override func handle(url: NSURL) {
        targetURL = url
        super.handle(url)
        
        loadAddressURL()
    }

    func loadAddressURL() {
        let req = NSMutableURLRequest(URL: targetURL)

        // Workarround to pass cookies from the shared cookie storage
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        let cookies = storage.cookies ?? []
        var headers = NSHTTPCookie.requestHeaderFieldsWithCookies(cookies)

        if headers["Cookie"] == nil {
            headers["Cookie"] = ""
        }

        req.allHTTPHeaderFields = headers

        self.webView.loadRequest(req)
    }

    // Workarround to save cookies to the shared cookie storage
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        let response = navigationResponse.response as! NSHTTPURLResponse
        let headers = response.allHeaderFields as! Dictionary<String, String>
        let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(headers, forURL: response.URL!)
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()

        for cookie in cookies {
            storage.setCookie(cookie)
        }

        decisionHandler(.Allow);
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if let dismissUrl = dismissUrl {
            // Handle callback URL
            if let url = navigationAction.request.URL where (url.scheme == dismissUrl.scheme && url.host == dismissUrl.host) {
                decisionHandler(.Cancel)
                self.dismissWebViewController()

                SevenPass.handleOpenURL(url)

                return
            }
        }
        
        decisionHandler(.Allow)
    }
}