// -----------------------------------------------------------------------------
// Init service worker
// -----------------------------------------------------------------------------
let goappSWRegistration

if ('serviceWorker' in navigator) {
  navigator.serviceWorker
    .register('/goapp.js')
    .then(function (registration) {
      goappSWRegistration = registration
      console.log('goapp service worker registration successful with scope: ', registration.scope)
    })
    .catch(function (err) {
      console.error('goapp service worker registration failed', err)
    })
}

// -----------------------------------------------------------------------------
// Init progressive app
// -----------------------------------------------------------------------------
let deferredPrompt

window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault()
  deferredPrompt = e
  console.log('beforeinstallprompt')
})

// -----------------------------------------------------------------------------
// Init Web Assembly
// -----------------------------------------------------------------------------
if (!WebAssembly.instantiateStreaming) {
  WebAssembly.instantiateStreaming = async (resp, importObject) => {
    const source = await (await resp).arrayBuffer()
    return await WebAssembly.instantiate(source, importObject)
  }
}

const go = new Go()

WebAssembly
  .instantiateStreaming(fetch('/goapp.wasm'), go.importObject)
  .then((result) => {
    go.run(result.instance)
  })
  .catch(err => {
    const loadingIcon = document.getElementById('App_LoadingIcon')
    loadingIcon.className = ''

    const loadingLabel = document.getElementById('App_LoadingLabel')
    loadingLabel.innerText = err
    console.error('loading wasm failed: ' + err)
  })
