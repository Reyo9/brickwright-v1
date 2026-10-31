(function(){
  function $(s){ return document.querySelector(s); }
  function init(){
    var B = window.BW;
    function show(code){ $('#pMake').hidden = true; $('#pCode').hidden = false; $('#pCodeIn').value = code; $('#pHint').textContent = 'Paste this into the plugin. Making a new code turns the old one off.'; }
    $('#pMake').onclick = async function(){
      if (!B.session()) { B.openLogin(); return; }
      try { var j = await B.api('/api/plugin', {method: 'POST', body: {action: 'link'}}); show(j.code); } catch (e) { B.toast(e.message || 'Failed', true); }
    };
    $('#pCopy').onclick = function(){ navigator.clipboard.writeText($('#pCodeIn').value).then(function(){ B.toast('Code copied — paste it into the plugin.'); }); };
    $('#pRevoke').onclick = async function(){
      try { await B.api('/api/plugin', {method: 'POST', body: {action: 'unlink'}}); $('#pCode').hidden = true; $('#pMake').hidden = false; B.toast('Plugin code turned off.'); } catch (e) { B.toast(e.message, true); }
    };
  }
  if (window.BW) init(); else document.addEventListener('bw:ready', init);
})();
