class Net::ICAPUnknownResponse < Net::ICAPResponse
  HAS_BODY = true
end
class Net::ICAPInformation < Net::ICAPResponse
  HAS_BODY = false
end
class Net::ICAPSuccess < Net::ICAPResponse
  HAS_BODY = true
end
class Net::ICAPRedirection < Net::ICAPResponse
  HAS_BODY = true
end
class Net::ICAPClientError < Net::ICAPResponse
  HAS_BODY = true
end
class Net::ICAPServerError < Net::ICAPResponse
  HAS_BODY = true
end

class Net::ICAPContinue < Net::ICAPInformation; end               # 100

class Net::ICAPOK < Net::ICAPSuccess; end                         # 200
class Net::ICAPNoContent < Net::ICAPSuccess                       # 204
  HAS_BODY = false
end

class Net::ICAPBadRequest < Net::ICAPClientError                  # 400
  HAS_BODY = false
end
class Net::ICAPServiceNotFound < Net::ICAPClientError; end        # 404
class Net::ICAPMethodNotAllowed < Net::ICAPClientError; end       # 405
class Net::ICAPRequestTimeout < Net::ICAPClientError; end         # 408

class Net::ICAPInternalServerError < Net::ICAPServerError; end    # 500
class Net::ICAPMethodNotImplemented < Net::ICAPServerError; end   # 501
class Net::ICAPBadGateway < Net::ICAPServerError; end             # 502
class Net::ICAPServiceUnavailable < Net::ICAPServerError; end     # 503
class Net::ICAPVersionNotSupported < Net::ICAPServerError; end    # 505

class Net::ICAPResponse
  CODE_CLASS_TO_OBJ = {
    '1' => Net::ICAPInformation,
    '2' => Net::ICAPSuccess,
    '3' => Net::ICAPRedirection,
    '4' => Net::ICAPClientError,
    '5' => Net::ICAPServerError
  }
  CODE_TO_OBJ = {
    '100' => Net::ICAPContinue,

    '200' => Net::ICAPOK,
    '204' => Net::ICAPNoContent,

    '400' => Net::ICAPBadRequest,
    '404' => Net::ICAPServiceNotFound,
    '405' => Net::ICAPMethodNotAllowed,
    '408' => Net::ICAPRequestTimeout,

    '500' => Net::ICAPInternalServerError,
    '501' => Net::ICAPMethodNotImplemented,
    '502' => Net::ICAPBadGateway,
    '503' => Net::ICAPServiceUnavailable,
    '505' => Net::ICAPVersionNotSupported
  }
end

