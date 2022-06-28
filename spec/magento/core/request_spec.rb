RSpec.describe Magento::Request do
  let(:config) do
    double('Magento::Configuration',
      url: 'https://site.com.br',
      token: 'magento-token',
      store: 'magento-store',
      timeout: 30,
      open_timeout: 5
    )
  end

  subject { Magento::Request.new(config: config) }

  let(:response) do
    double('Response', parse: {}, status: double(:status, success?: true))
  end

  describe '#get' do
    it 'calls HTTP.get with url' do
      expect_any_instance_of(HTTP::Client).to receive(:get)
        .with('https://site.com.br/rest/magento-store/V1/products', {})
        .and_return(response)

      subject.get('products')
    end

    context 'with SSL disabled' do
      before do
        allow(ENV)
          .to receive(:fetch)
          .with('MAGENTO_ALLOW_SELF_SIGNED_SSL_CERT_ENABLED', false)
          .and_return('true')
      end

      it 'calls HTTP.get with url on non-HTTPS' do
        expect_any_instance_of(HTTP::Client).to receive(:get)
          .with(
            'https://site.com.br/rest/magento-store/V1/products',
            ssl_context: OpenSSL::SSL::SSLContext
          )
          .and_return(response)

        subject.get('products')
      end
    end
  end

  describe '#put' do
    it 'calls HTTP.put with url and body' do
      body = { product: { price: 22.50 } }

      expect_any_instance_of(HTTP::Client).to receive(:put)
        .with('https://site.com.br/rest/magento-store/V1/products', { json: body })
        .and_return(response)

      subject.put('products', body)
    end

    context 'with SSL disabled' do
      before do
        allow(ENV)
          .to receive(:fetch)
          .with('MAGENTO_ALLOW_SELF_SIGNED_SSL_CERT_ENABLED', false)
          .and_return('true')
      end

      it 'calls HTTP.get with url on non-HTTPS' do
        body = { product: { price: 22.50 } }

        expect_any_instance_of(HTTP::Client).to receive(:put)
          .with(
            'https://site.com.br/rest/magento-store/V1/products',
            {
              json: body,
              ssl_context: OpenSSL::SSL::SSLContext
            }
          )
          .and_return(response)

        subject.put('products', body)
      end
    end
  end

  describe '#post' do
    it 'calls HTTP.post with url and body' do
      body = { product: { name: 'Some name', price: 22.50 } }

      expect_any_instance_of(HTTP::Client).to receive(:post)
        .with('https://site.com.br/rest/magento-store/V1/products', { json: body })
        .and_return(response)

      subject.post('products', body)
    end

    context 'with SSL disabled' do
      before do
        allow(ENV)
          .to receive(:fetch)
          .with('MAGENTO_ALLOW_SELF_SIGNED_SSL_CERT_ENABLED', false)
          .and_return('true')
      end

      it 'calls HTTP.get with url on non-HTTPS' do
        body = { product: { name: 'Some name', price: 22.50 } }

        expect_any_instance_of(HTTP::Client).to receive(:post)
          .with(
            'https://site.com.br/rest/magento-store/V1/products',
            {
              json: body,
              ssl_context: OpenSSL::SSL::SSLContext
            }
          )
          .and_return(response)

        subject.post('products', body)
      end
    end
  end

  describe '#delete' do
    it 'calls HTTP.selete with url' do
      expect_any_instance_of(HTTP::Client).to receive(:delete)
        .with('https://site.com.br/rest/magento-store/V1/products/22', {})
        .and_return(response)

      subject.delete('products/22')
    end

    context 'with SSL disabled' do
      before do
        allow(ENV)
          .to receive(:fetch)
          .with('MAGENTO_ALLOW_SELF_SIGNED_SSL_CERT_ENABLED', false)
          .and_return('true')
      end

      it 'calls HTTP.get with url on non-HTTPS' do
        expect_any_instance_of(HTTP::Client).to receive(:delete)
          .with(
            'https://site.com.br/rest/magento-store/V1/products/22',
            ssl_context: OpenSSL::SSL::SSLContext
          )
          .and_return(response)

        subject.delete('products/22')
      end
    end
  end

  context 'private method' do
    describe '#http_auth' do
      it 'calls HTTP.auth with token and returns HTTP::Client' do
        expect(HTTP).to receive(:auth).with("Bearer #{config.token}").and_return(HTTP)
        result = subject.send(:http_auth)
        expect(result).to be_a(HTTP::Client)
      end
    end

    describe '#base_url' do
      it do
        base_url = "https://site.com.br/rest/magento-store/V1"
        expect(subject.send(:base_url)).to eql(base_url)
      end
    end

    describe '#url' do
      it 'returns base_url + resource' do
        url = "https://site.com.br/rest/magento-store/V1/products"
        expect(subject.send(:url, 'products')).to eql(url)
      end
    end

    describe '#handle_error' do
      context 'when success' do
        it 'does nothing' do
          subject.send(:handle_error, response)
        end
      end

      context 'when status not found' do
        it 'reises Magento::NotFound error' do
          allow(response).to receive(:status).and_return(
            double(:status, success?: false, not_found?: true, code: 404)
          )

          expect { subject.send(:handle_error, response) }.to raise_error(Magento::NotFound)
        end
      end

      context 'when other status' do
        it 'reises Magento::MagentoError' do
          allow(response).to receive(:status).and_return(
            double(:status, success?: false, not_found?: false, code: 422)
          )

          expect { subject.send(:handle_error, response) }.to raise_error(Magento::MagentoError)
        end
      end
    end

    describe '#save_request' do
      it 'save on instance variable' do
        body = { quantity: 200, category_ids: [1,3,4] }

        subject.send(:save_request, :post, 'https:someurl.com.br', body)

        expect(subject.instance_variable_get(:@request)).to eql({
          body: body,
          method: :post,
          url: 'https:someurl.com.br',
        })
      end

      context 'when body has media_gallery_entries' do
        it 'removes media_gallery_entries attribute from body' do
          body = { product: { name: 'Name', price: 99.90, media_gallery_entries: {} } }

          subject.send(:save_request, :post, 'https:someurl.com.br', body)

          expect(subject.instance_variable_get(:@request)).to eql({
            body: { name: 'Name', price: 99.90 },
            method: :post,
            url: 'https:someurl.com.br',
          })
        end
      end
    end
  end
end
