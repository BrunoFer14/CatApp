import Foundation
enum secrets{
    static var catApiKey : String {
        guard let key = Bundle.main.infoDictionary?["CAT_API_KEY"] as? String else {
            fatalError("Missing CAT_API_KEY in Info.plist")
        }
        return key
    }
}

