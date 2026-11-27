import Foundation
import JavaScriptCore

public class ScriptRuntime {
    private let vm = JSVirtualMachine()
    private var context: JSContext?

    public init() {
        resetContext()
    }

    public func resetContext() {
        guard let newContext = JSContext(virtualMachine: vm) else { return }
        self.context = newContext

        // Mock console.log
        let consoleLog: @convention(block) (String) -> Void = { message in
            NSLog("[EmsaProxy-JS] %@", message)
        }
        newContext.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString)
        newContext.evaluateScript("var console = { log: consoleLog, warn: consoleLog, error: consoleLog };")

        // Mock $notify
        let notify: @convention(block) (String, String, String) -> Void = { title, subtitle, message in
            NSLog("[EmsaProxy-Notify] %@ - %@: %@", title, subtitle, message)
        }
        newContext.setObject(notify, forKeyedSubscript: "$notify" as NSString)

        // Mock $done
        let done: @convention(block) (JSValue) -> Void = { result in
            NSLog("[EmsaProxy-Done] Result callback")
        }
        newContext.setObject(done, forKeyedSubscript: "$done" as NSString)
    }

    public func runScript(source: String, url: String, headers: [String: String], body: String?) -> (headers: [String: String], body: String?) {
        guard let ctx = context else { return (headers, body) }

        let req: [String: Any] = [
            "url": url,
            "headers": headers,
            "body": body ?? ""
        ]
        ctx.setObject(req, forKeyedSubscript: "$request" as NSString)

        ctx.evaluateScript(source)

        if let modified = ctx.objectForKeyedSubscript("$response"), !modified.isUndefined {
            let resHeaders = modified.objectForKeyedSubscript("headers")?.toDictionary() as? [String: String] ?? headers
            let resBody = modified.objectForKeyedSubscript("body")?.toString() ?? body
            return (resHeaders, resBody)
        }

        return (headers, body)
    }
}
