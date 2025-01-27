/** script.js
 * 
 */


window.chrome.webview.addEventListener('message', ahkWebMessage);
function ahkWebMessage(Msg) {
    console.log(Msg.data);
    try {
        eval(Msg.data);
    }
    catch(err){
        console.log("Failed to execute");
    }
}


function ahkFormSubmit(Event) {
    let EventInfo = (Event.target.id != "" || "") ? Event.target.id : (Event.target.name != null || "") ? Event.target.name : Event.target.outerHTML;
    ahk.ahkFormSubmit(EventInfo);
}



/** Context menus - based on https://dev.to/iamafro/how-to-create-a-custom-context-menu--5d7p */

const contextmenus = new Map();
contextmenus.set("app-power", {menu: document.querySelector("#context-menu-power"), visible: false} );
contextmenus.set("app-VPN", {menu: document.querySelector("#context-menu-VPN"), visible: false} );
contextmenus.set("app-EI", {menu: document.querySelector("#context-menu-EI"), visible: false} );
contextmenus.set("app-PS", {menu: document.querySelector("#context-menu-PS"), visible: false} );
contextmenus.set("app-EPIC", {menu: document.querySelector("#context-menu-EPIC"), visible: false} );

const toggleMenu = (v, command) => {
    if (command === "show") {
        v.menu.style.display = "block";
        v.visible = true;
    } else {
        v.menu.style.display = "none";
        v.visible = false;
    }
};

const setPosition = (val, { top, left }) => {
    top = top - 15;
    left = left - 150;
    val.menu.style.left = `${left}px`;
    val.menu.style.top = `${top}px`;

    contextmenus.forEach( (v, k) => {
        if (v === val) {
            toggleMenu(v, "show");
        } else if (v.visible) {
            toggleMenu(v, "hide");
        }
    })
};

document.addEventListener("click", e => {
    contextmenus.forEach( (v, k) => {
        if (v.visible) {
            toggleMenu(v, "hide")
        }
    })
});

document.querySelectorAll(".context-menu-target").forEach( m => {
    m.addEventListener("contextmenu", e => {
        e.preventDefault();
        const origin = {
            left: e.clientX,
            top: e.clientY
        };
        setPosition(contextmenus.get(e.target.id), origin);
        return false;
        });
});
