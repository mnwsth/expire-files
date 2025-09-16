import Cocoa

class ExpirationDatePickerViewController: NSViewController {
    
    private var fileURL: URL
    var onDateSet: ((Date) -> Void)?
    
    private let datePicker = NSDatePicker()
    
    init(fileURL: URL, existingDate: Date?) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
        if let date = existingDate {
            datePicker.dateValue = date
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 150))
        setupViews()
    }
    
    private func setupViews() {
        let titleLabel = NSTextField(labelWithString: "Set Expiration for:")
        let fileNameLabel = NSTextField(labelWithString: fileURL.lastPathComponent)
        fileNameLabel.font = NSFont.boldSystemFont(ofSize: 13)
        
        datePicker.datePickerStyle = .textFieldAndStepper
        datePicker.datePickerElements = [.yearMonthDay, .hourMinute]
        
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveAction))
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelAction))
        
        let stackView = NSStackView(views: [titleLabel, fileNameLabel, datePicker, NSView(), saveButton, cancelButton])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonStack = NSStackView(views: [cancelButton, saveButton])
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        
        let mainStack = NSStackView(views: [titleLabel, fileNameLabel, datePicker, buttonStack])
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    @objc private func saveAction() {
        onDateSet?(datePicker.dateValue)
        dismiss(self)
    }
    
    @objc private func cancelAction() {
        dismiss(self)
    }
} 