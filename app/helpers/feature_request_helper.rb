module FeatureRequestHelper
  FEATURE_REQUEST_COPY = {
    "specialty" => {
      link: "Don't see your specialty?",
      title: "Request a specialty",
      lead: nil,
      label: "Which specialty are you missing?",
      label_help: "We review every request and email you when we add it.",
      placeholder: "e.g. Polyvagal Therapy — and a quick note on why it matters to your practice"
    },
    "service" => {
      link: "Don't see your service?",
      title: "Request a service",
      lead: nil,
      label: "Which service are you missing?",
      label_help: "We review every request and email you when we add it.",
      placeholder: "e.g. Group consultation for new clinicians"
    },
    "insurance_company" => {
      link: "Don't see your insurance company?",
      title: "Request an insurance company",
      lead: "Tell us which insurance company you'd like to see added. We review every request and email you when we add it.",
      label: "Insurance company",
      placeholder: "Company name and any helpful details (state, plan type, etc.)"
    },
    "college" => {
      link: "Don't see your college?",
      title: "Request a college",
      lead: "Tell us about a college you'd like to see added. We review every request and email you when we add it.",
      label: "College",
      placeholder: "College name, location, any helpful details"
    },
    "general" => {
      link: "Feature request",
      title: "Request a feature",
      lead: nil,
      label: "What would make this app better?",
      label_help: "We review every request and email you back if we build it.",
      placeholder: "Describe the feature you'd like us to add"
    }
  }.freeze

  def feature_request_copy(kind)
    FEATURE_REQUEST_COPY.fetch(kind.to_s)
  end
end
