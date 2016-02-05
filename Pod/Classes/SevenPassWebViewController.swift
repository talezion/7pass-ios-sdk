import OAuthSwift_p7s1
import WebKit

typealias WebView = WKWebView

public class SevenPassWebViewController: OAuthWebViewController, SevenPassURLHandlerType, WKNavigationDelegate {
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
    
    override public func viewDidLoad() {
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
    
    override public func handle(url: NSURL) {
        targetURL = url
        super.handle(url)
        
        loadAddressURL()
    }

    func loadAddressURL() {
        let req = NSMutableURLRequest(URL: targetURL)

        self.webView.loadRequest(req)
    }

    public func destroySession(logoutUrl: NSURL) {
        // Remove all 7pass.sess* cookies on a correct domain
        webView.loadHTMLString("<script type=\"text/javascript\">document.cookie.match(/7pass\\.sess[a-za-z0-9.]*/gi).forEach(function(cookieName) { document.cookie = cookieName + '=; path=/; domain=' + document.domain + '; expires=' + new Date(0).toUTCString(); })</script>", baseURL: logoutUrl)
    }

    public func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
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