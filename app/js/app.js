(function(){
  const changeEvents = ['input', 'change', 'keyup', 'paste'];
  const defaultMetadata = JSON.stringify({
    from: "",
    to: "",
    cc: "",
    bcc: "",
    subject: "",
    styles: ""
  });

  pp = (obj) => {
    return JSON.stringify(obj, null, 2);
  };

  validJSONObject = strOrObj => {
    if (typeof strOrObj === 'object' && strOrObj !== null) {
      return strOrObj // An object
    }

    try {
      let json = JSON.parse(strOrObj);

      if (typeof json !== 'object' || json === null || json == undefined) {
        return false
      }

      return json
    }
    catch(err) {
      // console.error(err)
      return false;
    }
  };

  validJSONObjectAsStr = (str, defaultObjStr) => {
    let json = validJSONObject(str);

    if (json) {
      return JSON.stringify(json);
    }

    return defaultObjStr;
  }

  addBlock = (el, updateFn) => {
    return async function() {
      const blocks = getConfig('blocks', '[]');
      const blocksEl = document.querySelector('.config .blocks textarea');

      const response = await fetch(`/block?type=${el.dataset.type}`);
      const block = await response.json();

      blocks.push(block);

      blocksEl.value = pp(blocks);
      updateFn()
    }
  }

  updateBuilderConfig = (key, el) => {
    return () => {
      let str = el.value;
      let builder = getConfig('builder', '{}');

      builder[key] = str;

      setConfig('builder', builder);
    }
  }

  updateConfig = (key, el, defaultObj) => {
    return () => {
      let str = el.value;

      if (str === "") {
        str = defaultObj;
      }

      let json = validJSONObject(str)
      let current = getConfig(key, defaultObj);

      if (json && JSON.stringify(json) !== JSON.stringify(current)) {
        setConfig(key, el.value);
        el.innerHTML = pp(json);
        el.value = pp(json);
        render();
      }
    }
  };

  setConfig = (key, value) => {
    localStorage.setItem(key, validJSONObjectAsStr(value));
  };

  getConfig = (key, defaultObj) => {
    let str = localStorage.getItem(key);
    let json = validJSONObjectAsStr(str, defaultObj);

    return JSON.parse(json);
  };

  // TODO: Do not reload the page ... update all the fields ...
  newNewsletter = () => {
    localStorage.clear();
    window.location.reload();
  };

  // TODO: Do not reload the page ... update all the fields ...
  openNewsletter = () => {
    var input = document.createElement('input');
    input.type = 'file';
    input.addEventListener('change', () => {
      const file = input.files[0];
      const reader = new FileReader();

      reader.readAsText(file,'UTF-8');

      reader.onload = async function (readerEvent) {
        const content = readerEvent.target.result;
        let metadata = validJSONObject(content) || {};
        const blocks = metadata['blocks'];
        const stylePath = metadata['styles'];
        let styles = {};
        let builder = {};
        delete metadata['blocks'];

        console.log(metadata)
        console.log(stylePath)
        if (stylePath) {
          styles = await getStyles(stylePath);
          builder['styles'] = stylePath;
        }

        setConfig('metadata', metadata);
        setConfig('blocks', blocks);
        setConfig('builder', builder);
        setConfig('styles', styles);

        window.location.reload()
      }
    });
    input.click();
  }
  async function getStyles(path) {
    try {
      const response = await fetch(`/styles?path=${path}`, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' }
      });
      return await response.json();
    } catch(err) {
      console.error(`failed to get style "${path}": ${err}`);
      return {};
    }
  }

  async function saveStyles() {
    const styles = getConfig('styles', '{}');
    const name = getConfig('builder', '{}')['styles'];

    const data = { styles: styles, name: name };

    await fetch('/styles', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
  }

  async function saveConfig() {
    const metadata = getConfig('metadata', defaultMetadata);
    const blocks = getConfig('blocks', '[]');
    const builder = getConfig('builder', '{}');
    const path = builder['path'];
    const styles = builder['styles'];

    config = metadata;
    config['blocks'] = blocks;
    if (styles) {
      config['styles'] = styles
    }

    const data = { config: config, path: path };

    await fetch('/config', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
  }

  async function render() {
    const metadata = getConfig('metadata', defaultMetadata);
    const blocks = getConfig('blocks', '[]');
    const styles = getConfig('styles', '{}');

    config = metadata;
    config['blocks'] = blocks;

    const data = { config: config, styles: styles };

    const response = await fetch('/render', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    const json = await response.json();

    const htmlEl = document.querySelector('.rendered .html');
    const markdownEl = document.querySelector('.rendered .markdown');

    htmlEl.innerHTML = json.html;
    markdownEl.innerHTML = json.markdown;
  }

  togglePreview = () => {
    const htmlEl = document.querySelector('.rendered .html');
    const markdownEl = document.querySelector('.rendered .markdown');
    const builder = getConfig('builder', '{}');

    htmlEl.classList.toggle('hidden');
    markdownEl.classList.toggle('hidden');

    if (htmlEl.classList.contains('hidden')) {
      builder['preview'] = 'markdown';
    } else {
      builder['preview'] = 'html';
    }

    setConfig('builder', builder)
  };

  async function init() {
    const metadata = getConfig('metadata', defaultMetadata);
    const blocks = getConfig('blocks', '[]');
    const builder = getConfig('builder', '{}');

    let styles = getConfig('styles', '{}');

    const stylePath = metadata['styles'];

    if (Object.entries(styles).length === 0 && stylePath) {
      styles = await getStyles(stylePath);
      setConfig('styles', styles);
    }

    const metadataEl = document.querySelector('.config .metadata textarea');
    const blocksEl = document.querySelector('.config .blocks textarea');
    const stylesEl = document.querySelector('.config .styles textarea');
    const configPathEl = document.querySelector('.config .configpath input');
    const stylePathEl = document.querySelector('.config .stylepath input');

    const previewToggleEl = document.querySelector('.options .options__toggle-preview');
    const newEl = document.querySelector('.options .options__new');
    const openEl = document.querySelector('.options .options__open');
    const saveConfigEl = document.querySelector('.save-config');
    const saveStylesEl = document.querySelector('.save-styles');

    const addBlockEls = document.querySelectorAll('.options .options__add-block');

    metadataEl.innerHTML = pp(metadata);
    blocksEl.innerHTML = pp(blocks);
    stylesEl.innerHTML = pp(styles);
    configPathEl.value = builder['path'] || "";
    stylePathEl.value = builder['styles'] || stylePath;

    updateMetadata = updateConfig('metadata', metadataEl, defaultMetadata);
    updateBlocks = updateConfig('blocks', blocksEl, '[]');
    updateStyles = updateConfig('styles', stylesEl, '{}');
    updateConfigPath = updateBuilderConfig('path', configPathEl);
    updateStylePath = updateBuilderConfig('styles', stylePathEl);

    changeEvents.forEach(event => {
      metadataEl.addEventListener(event, updateMetadata);
      blocksEl.addEventListener(event, updateBlocks);
      stylesEl.addEventListener(event, updateStyles);
      configPathEl.addEventListener(event, updateConfigPath);
      stylePathEl.addEventListener(event, updateStylePath);
    });

    previewToggleEl.addEventListener('click', togglePreview);
    if (builder['preview'] === 'markdown') {
      togglePreview();
    }

    saveConfigEl.addEventListener('click', saveConfig);
    saveStylesEl.addEventListener('click', saveStyles);
    newEl.addEventListener('click', newNewsletter);
    openEl.addEventListener('click', openNewsletter);

    Array.from(addBlockEls).forEach(el => {
      el.addEventListener('click', addBlock(el, updateBlocks));
    });

    render();
  };

  if (document.readyState !== 'loading') {
    init();
  } else {
    document.addEventListener('DOMContentLoaded', init);
  }
})();
