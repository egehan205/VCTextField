//
//  VCTextField.swift
//  VCTextField
//
//  Created by Egehan KARAKÖSE (Dijital Kanallar Uygulama Geliştirme Müdürlüğü) on 2.09.2022.
//

import Foundation

public class VCTextFieldViewModel {
    public var text: String? = nil
    public var placeholder: String?
    public var validators: [Validator]? = nil
    public var textChangeHandler: ((_ newValue: String?) -> Void)? = nil
    public var endEditingHandler: ((_ newValue: String?) -> Void)? = nil
    public var beginEditingHandler: ((_ newValue: String?) -> Void)? = nil
    var errorText: String? = nil
    public var clearValidation = Observable<Bool>()
    public var validated: BoolHandler?
    public var allowedCharacters: CharacterSet? = .alphanumerics
    public var contentType: UITextContentType? = .username
    public var validationTextColor: UIColor?
    public var validationTextFont: UIFont?
    public var validationTextLabelHeight: CGFloat?
    
    
    public var tf_maxLength: Int = .max
    public var tf_maskString: String?
    public var tf_cornerRadius: CGFloat?
    public var tf_font: UIFont?
    public var tf_backgroundColor: UIColor?
    public var tf_textColor: UIColor?
    public var tf_tintColor: UIColor?
    public var tf_borderWidth: CGFloat?
    public var tf_borderColor: CGColor?
    public var tf_placeHolderColor: UIColor?
    public var tf_height: CGFloat?
    
    public init(placeholder: String?) {
        self.placeholder = placeholder
    }
}

public class VCTextField: UIView {
   
    var label: UILabel = UILabel()
    public private(set) var viewModel: VCTextFieldViewModel
    var textField: TextFieldWithInsets?
    
    var isValid: Bool? {
        didSet {
            guard let isValid = isValid else { return }
            viewModel.validated?(isValid)
        }
    }
    public init(viewModel: VCTextFieldViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        self.addCustomView()
        
    }
    
    var labelHeightAnchor: NSLayoutConstraint?
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addCustomView() {
        let textFieldViewModel = TextFieldWithInsetsViewModel(placeHolder: (viewModel.placeholder)~)
        textFieldViewModel.placeHolderColor = viewModel.tf_placeHolderColor
        textFieldViewModel.borderColor = viewModel.tf_borderColor
        textFieldViewModel.borderWidth = viewModel.tf_borderWidth
        textFieldViewModel.tintColor = viewModel.tf_tintColor
        textFieldViewModel.backgroundColor = viewModel.tf_backgroundColor
        textFieldViewModel.textColor = viewModel.tf_textColor
        textFieldViewModel.font = viewModel.tf_font
        textFieldViewModel.allowedCharacters = viewModel.allowedCharacters
        textFieldViewModel.height = viewModel.tf_height
        
        textFieldViewModel.textChangedHandler = {[weak self] newValue in
            self?.viewModel.text = newValue
            self?.validate()
            self?.viewModel.textChangeHandler?(newValue)
        }
        
        viewModel.clearValidation.addObserver {[weak self] clear in
            if clear {
                self?.clearValidation()
            }
        }
        
        textFieldViewModel.textBeginEditingHandler = { [weak self] newValue in
            guard let self = self else { return }
            self.viewModel.clearValidationState()
            self.viewModel.beginEditingHandler?(newValue)
        }
        
        textFieldViewModel.textEndEditingHandler = { [weak self] newValue in
            guard let self = self else { return }
            self.viewModel.text = newValue
            self.validate()
            if !(self.isValid ?? true) {
                self.showValidationAnimation(isShow: true)
            }
            self.label.text = self.viewModel.errorText
            self.label.isHidden = self.isValid~
            self.viewModel.endEditingHandler?(newValue)
        }
        
        textField = TextFieldWithInsets(viewModel: textFieldViewModel)
        guard let textField = textField else { return }

        textField.configureTextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textContentType = viewModel.contentType
        textField.isSecureTextEntry = viewModel.contentType == .password || viewModel.contentType == .newPassword
        textField.translatesAutoresizingMaskIntoConstraints = false
       
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor =  viewModel.validationTextColor//.appMainBackgroundColor
        label.isHidden = true
        label.font = viewModel.validationTextFont // .regular(of: 12)
        
        self.addSubview(textField)
        self.addSubview(label)
        
        labelHeightAnchor = label.heightAnchor.constraint(equalToConstant: 0)
        labelHeightAnchor?.isActive = true
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: self.topAnchor),
            textField.widthAnchor.constraint(equalTo: self.widthAnchor),
            label.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 5),
            label.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 10),
            label.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -2)
        ])
        
    }
    
    public func setText(text: String) {
        textField?.text = text
    }
    
    public func clearValidation() {
        label.isHidden = true
        showValidationAnimation()
    }
    
    @discardableResult public func validate(_ forContinue: Bool = false) -> Bool? {
        if let validators = viewModel.validators {
            isValid = viewModel.validate(with: validators, setErrorText: true)
            if forContinue {
                if !(isValid ?? true) {
                    showValidationAnimation(isShow: true)
                }
                label.text = viewModel.errorText
                label.isHidden = isValid~
            }
        }
        return isValid
    }
    
    private func showValidationAnimation(isShow: Bool = false) {
        let duration = 0.2
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            self.labelHeightAnchor?.constant = isShow ? (self.viewModel.validationTextLabelHeight ?? 14) : 0
            self.layoutIfNeeded()
        }
        animator.addCompletion { position in
            if position == .end {
                isShow ? self.shake() : nil
            }
        }
        animator.startAnimation()
    }
    
}

extension VCTextFieldViewModel: Validatable {
    
    // swiftlint:disable cyclomatic_complexity
    public func validate(with validators: [Validator], setErrorText: Bool) -> Bool {
        for validator in validators {
            if let requiredValidator = validator as? RequiredValidator {
                if text == nil || text!.isEmpty {
                    if setErrorText { errorText = requiredValidator.message }
                    return false
                }
            }
            if let trimValidator = validator as? TrimRequiredValidator {
                if trimValidator.validate(with: text ?? "") == false {
                    if setErrorText { errorText = trimValidator.message }
                    return false
                }
            }
            if let minimumLengthValidator = validator as? MinimumLengthValidator {
                if minimumLengthValidator.validate(with: text) == false {
                    if setErrorText { errorText = minimumLengthValidator.message }
                    return false
                }
            }
            if let minimumValueValidator = validator as? MinimumValueValidator {
                if minimumValueValidator.validate(with: Double(text ?? "")) == false {
                    if setErrorText { errorText = minimumValueValidator.message }
                    return false
                }
            }
            if let maximumValueValidator = validator as? MaximumValueValidator {
                if maximumValueValidator.validate(with: Double(text?.getNumbers ?? "")) == false {
                    if setErrorText { errorText = maximumValueValidator.message }
                    return false
                }
            }
            if let cardNumberValidator = validator as? CreditCardNumberValidator {
                if cardNumberValidator.validate(with: text) == false {
                    if setErrorText { errorText = cardNumberValidator.message }
                    return false
                }
            }
            if let phoneNumberValidator = validator as? PhoneNumberValidator {
                if phoneNumberValidator.validate(with: text) == false {
                    if setErrorText { errorText = phoneNumberValidator.message }
                    return false
                }
            }
            if let onlyNumbersValidator = validator as? OnlyNumbersValidator {
                if onlyNumbersValidator.validate(with: text) == false {
                    if setErrorText { errorText = onlyNumbersValidator.message }
                    return false
                }
            }
            
            if let transactionDayValidator = validator as? TransactionDayValidator {
                if transactionDayValidator.validate(with: text) == false {
                    if setErrorText { errorText = transactionDayValidator.message }
                    return false
                }
            }
            
            if let regexValidator = validator as? RegexValidator {
                if regexValidator.validate(with: text) == false {
                    if setErrorText { errorText = regexValidator.message }
                    return false
                }
            }
            
            if let functionValidator = validator as? FunctionValidator {
                if functionValidator.function() == false {
                    if setErrorText { errorText = functionValidator.message }
                    return false
                }
            }
            
            if let plateValidator = validator as? PlateValidator {
                if plateValidator.validate(with: text) == false {
                    if setErrorText { errorText = plateValidator.message }
                    return false
                }
            }
        }
        return true
    }
    // swiftlint:enable cyclomatic_complexity
    
    public func clearValidationState() {
        errorText = nil
        clearValidation.data = true
    }
}