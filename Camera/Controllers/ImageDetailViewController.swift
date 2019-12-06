import UIKit

class ImageDetailViewController: UIViewController {

    var image: UIImage?
    @IBOutlet private weak var imageView: ZoomImageView!
    @IBOutlet private weak var closeButton: PulsingButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image

        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 10
    }

    @IBAction private func closeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let value: T

    init(key: String, default value: T) {
        self.key = key
        self.value = value
    }

    var wrappedValue: T {
        get { return UserDefaults.standard.value(forKey: key) as? T ?? self.value }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
