module Fusuma
  # vector data
  class Tap
    TYPE = 'tap'.freeze


    def direction
      'out'
    end

    def enough?(trigger)
      MultiLogger.debug('tap')
      return true
    end


  end
end
