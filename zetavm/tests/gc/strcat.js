var test = function ()
{
    $rt_shrinkHeap(40000);

    var gcCount = $ir_get_gc_count();

    var strI = "foobarbiffoobarbif";

    var n = 0;

    while ($ir_get_gc_count() < gcCount + 2)
    {
        var str = strI + (n++) + strI;

        assert (typeof str == 'string');
    }

    return 0;
};
