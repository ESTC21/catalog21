xml = Builder::XmlMarkup.new
xml.instruct!
xml.text!("\n")
xml.modify @response
	