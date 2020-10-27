async function nonJs() 
{

    console.log('nonJs was called');

    return new Promise( (resolve) =>
        {
            resolve(true);
        }
    );
}


on('__internal:asyncExports.Call', async (callback_id, resource, export_name, ... args) => 
    {
        if (resource == GetCurrentResourceName())
        {
            //console.log(`received asyncexport call try at ${callback_id} export ${export_name}`);

            const a = exports[resource][export_name](args);
            //const ret = await window[export_name](args);
            //eval(export_name, args)
            //const v = new Function(export_name);
            //v();
            //global[export_name]();
            //eval(export_name);
            //window[export_name]();

            console.log(`emitting anwser at ${callback_id}`);

            emit('__internal:asyncExports.Answer', callback_id);
        }
    }
);

exports('func', (cb) => 
    {
        (
            async() => 
            {

                console.log('callingback');

                cb(await nonJs()); 
            }
        )();
    }
);