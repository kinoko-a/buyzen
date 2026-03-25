module ApplicationHelper
  FLASH_STYLES = {
    notice:  "alert-info border-info/30",
    success: "alert-success border-success/40",
    warning: "alert-warning border-warning/30",
    alert:   "alert-error border-error/30"
  }.freeze

  def flash_class(type)
    FLASH_STYLES[type.to_sym] || "alert-info"
  end

  def flash_icon(type)
    {
      notice:  "information-circle",
      success: "checkmark-circle",
      warning: "alert-circle",
      alert:   "close-circle"
    }[type.to_sym] || "information-circle"
  end
end
