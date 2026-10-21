import Foundation

/// Optional caller-owned construction control; this key grants no content authority.
public enum ContentDigestDecodingContext {
  public static let controlKey: CodingUserInfoKey = {
    guard let key = CodingUserInfoKey(rawValue: "CircuiteFoundation.ContentDigest.construction-control") else {
      preconditionFailure("The fixed nonempty ContentDigest context key must be valid.")
    }
    return key
  }()
}
