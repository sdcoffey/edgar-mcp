# frozen_string_literal: true

def instance_mock(cls, *)
  dbl = instance_double(cls, *)
  allow(cls).to receive(:new).and_return(dbl)

  dbl
end
