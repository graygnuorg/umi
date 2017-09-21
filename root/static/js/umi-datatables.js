
var table = $('#dataTableToDraw').DataTable({
    "dom": '<"h6 col-12"i><"row container-fluid"<"col-6 pull-left btn-group"B><"col-6 pull-right"f>>rt<"row container-fluid clearfix"<"col-2"l><"col-10"p>>',
    "buttons": {
	"buttons": [
	    {
		extend: 'copy',
		text: '<i title="Copy current page data to clipboard" class="fa fa-copy fa-lg"></i>',
		className: 'btn btn-primary btn-sm',
		exportOptions: {
		    modifier: {
			page: 'current'
		    }
		},
	    },
	    {
		extend: 'print',
		text: '<i title="Print current page" class="fa fa-print fa-lg"></i>',
		className: 'btn btn-primary btn-sm',
		autoPrint: false,
		exportOptions: {
		    modifier: {
			page: 'current'
		    }
		},
	    },
	    {
		extend: 'csv',
		text: '<i title="Download current page as CSV file" class="fa fa-download fa-lg"></i>',
		className: 'btn btn-primary btn-sm',
		exportOptions: {
		    modifier: {
			page: 'current'
		    }
		},
	    },
	]
    },
    "renderer": {
        "header": "bootstrap",
        "pageButton": "bootstrap",
    },
    "search": {
	"regex": true,
	"smart": true,
    },
    "responsive": true,
    "order": [[ 0, 'asc' ]],
    // "paging": false,
    // "scrolly": 400,
    "select": true,
    // "displayLength": 25,
    "lengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
    "infoCallback": function( settings, start, end, max, total, pre ) {
	var infostr= start +' to '+ end +' of '+ total +' selected records from all, '+ max +' rows';
	return infostr;
    },
    "createdRow": function ( row, data, index ) {
	if ( data[2] == 1 ) {
	    $(row).addClass('danger');
	}
    },
    // "serverSide": true,
    "pagingType": "simple_numbers"
} );

// Order by the grouping
$('#dataTableToDraw tbody').on( 'click', 'tr.group', function () {
    var currentOrder = table.order()[0];
    if ( currentOrder[0] === 2 && currentOrder[1] === 'asc' ) {
	table.order( [ 2, 'desc' ] ).draw();
    }
    else {
	table.order( [ 2, 'asc' ] ).draw();
    }
} );
