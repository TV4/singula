defmodule Paywizard.DibsPaymentMethod do
  defstruct [
    :dibs_ccPart,
    :dibs_ccPrefix,
    :dibs_ccType,
    :dibs_expM,
    :dibs_expY,
    :transactionId,
    :receipt,
    defaultMethod: true
  ]

  @type t :: %__MODULE__{}

  def new(report) do
    %__MODULE__{
      transactionId: report.transactionId,
      receipt: report.verifyId,
      dibs_ccPart: report.ccPart,
      dibs_ccPrefix: report.ccPrefix,
      dibs_ccType: report.ccType,
      dibs_expM: report.expM,
      dibs_expY: report.expY
    }
  end
end
