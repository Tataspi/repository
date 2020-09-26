import UIKit


class SignupViewController: UIViewController {
    
    @IBOutlet private var emailTextField: TextField!
    @IBOutlet private var passwordTextField: TextField!
    @IBOutlet private var errorLabel: UILabel!
    private var emailAddress: String?
    private var completion: () -> Void
    
    init(emailAddress: String?, completion: @escaping () -> Void) {
        self.emailAddress = emailAddress
        self.completion = completion
        super.init(nibName: "SignupView", bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.text = emailAddress
        errorLabel.isHidden = true
    }
    
    @objc private func keyboardWillChangeFrame(notification: Notification) {
        let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let keyboardFrameInWindow = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTopOffset = self.view.bounds.maxY - self.view.convert(keyboardFrameInWindow, from: nil).minY
        self.view.layoutMargins.bottom = max(keyboardTopOffset, 0)
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction private func logIn() {
        self.navigationController?.setViewControllers([LoginViewController(emailAddress: emailTextField.text, completion: completion)], animated: true)
    }
    
    // This function is called when the Next button is pressed
    @IBAction private func proceedToNextStep() {
        self.view.endEditing(true)
        
        let emailAddress = emailTextField.text
        if let errorMessage = validate(emailAddress: emailAddress) {
            emailTextField.indicatesError = true
            errorLabel.text = errorMessage
            errorLabel.isHidden = false
            return
        }
        emailTextField.indicatesError = false
        
        let password = passwordTextField.text
        if let errorMessage = validate(password: password) {
            passwordTextField.indicatesError = true
            errorLabel.text = errorMessage
            errorLabel.isHidden = false
            return
        }
        passwordTextField.indicatesError = false
        
        self.view.isUserInteractionEnabled = false
        errorLabel.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ServerAPI.shared.signUp(emailAddress: emailAddress!, password: password!) { (user: User?, error: Error?) in
                if let user = user {
                    User.current = user
                    self.navigationController?.setViewControllers([ConfirmationCodeViewController(emailAddress: emailAddress!, completion: self.completion)], animated: true)
                } else {
                    self.report(error: error)
                }
            }
        }
    }
    
    // These functions perform input validation and return an error message if any
    private func validate(emailAddress: String?) -> String? {
        if emailAddress == nil || emailAddress!.count == 0 {
            return "Please enter your email address"
        }
        if emailAddress!.count < 6 || !emailAddress!.contains("@") {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    private func validate(password: String?) -> String? {
        if password == nil || password!.count == 0 {
            return "Please enter your password"
        }
        if password!.count < 3 {
            return "A password must contain at least 3 characters"
        }
        return nil
    }
}