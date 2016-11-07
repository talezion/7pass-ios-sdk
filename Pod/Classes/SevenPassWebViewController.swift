import OAuthSwift
import WebKit

typealias WebView = WKWebView

public class SevenPassWebViewController: OAuthWebViewController, SevenPassURLHandlerType, WKNavigationDelegate {
    var targetURL: URL!
    var webView: WebView = WebView()
    var toolbar: UIToolbar!
    var dismissUrl: URL?
    
    convenience init(urlString: String) {
        self.init()
        self.dismissUrl = URL(string: urlString)
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
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.close(sender:)))

        toolbar = UIToolbar()
        toolbar.items = [doneButton]
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(toolbar)

        // WebView & Toolbar to 100% width
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[webView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["webView": webView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[toolbar]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["toolbar": toolbar]))
        
        // WebView to 100% height
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[webView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil,
            views: [
                "webView": webView
            ]))
      
        // Align toolbar to the bottom, on top of the WebView
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[toolbar]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil,
            views: [
                "toolbar" :toolbar
            ]))
        
        loadAddressURL()
    }
    
    override open func handle(_ url: URL) {
        targetURL = url
        super.handle(url)
        
        loadAddressURL()
    }

    func loadAddressURL() {
        let req = URLRequest(url: targetURL)

        self.webView.load(req)
    }

    public func destroySession(logoutUrl: URL) {
        // Remove all 7pass.sess* cookies on a correct domain
        webView.loadHTMLString("<script type=\"text/javascript\">document.cookie.match(/7pass\\.sess[a-za-z0-9.]*/gi).forEach(function(cookieName) { var d = window.location.hostname.split('.'); while (d.length > 1) { document.cookie = cookieName + '=; path=/; domain=' + d.join('.') + '; expires=' + new Date(0).toUTCString(); d.shift(); } })</script>", baseURL: logoutUrl)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let dismissUrl = dismissUrl {
            // Handle callback URL
            if let url = navigationAction.request.url , (url.scheme == dismissUrl.scheme && url.host == dismissUrl.host) {
                decisionHandler(.cancel)
                self.dismissWebViewController()

                SevenPass.handleOpenURL(url)

                return
            }
        }
        
        decisionHandler(.allow)
    }
}
