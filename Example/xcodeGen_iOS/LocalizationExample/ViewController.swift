import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var nameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button.setTitle(localizedStrings.present, for: .normal)
        nameField.placeholder = localizedStrings.nameField.placeholder
        title = localizedStrings.title
    }

    @IBAction func buttonAction(_ sender: Any) {
        
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), name != "" else {
            return
        }
        
        let namespace = localizedStrings.hello

        let alert = UIAlertController(namespace: namespace, name: name, style: .alert)
        alert.addAction(UIAlertAction(title: namespace.done, style: .default, handler: { _ in }))
        
        present(alert, animated: true, completion: nil)
    }
}

protocol AlertNamespace {
    var title: String { get }
    func message(name: String) -> String
}

extension LocalizedStrings.Hello : AlertNamespace {}

extension UIAlertController {
    convenience init(namespace: AlertNamespace, name: String, style: UIAlertController.Style) {
        self.init(title: namespace.title, message: namespace.message(name: name), preferredStyle: .alert)
    }
}
