$(function(){
   $("#addbtn").on("click",addHost);
   $("#lb_save").on("click",saveLbGlobArg);
   $("#lb_stop").on("click",stopLbServer);
});

/*停止服务*/
function stopLbServer(){
 if(confirm("停止服务是危险的操作,是否继续?")){
	  $.get("/admin/lb/stop",function(res){
	      alert(res.info || res)
	  });   
  }   
}

/*将主机下线*/
function delHost(host,port){
  var err = $("#err_info");
  if($('#host_table').find("tr").length==1)
     return alert("只有一个主机,不能执行下线");
     
  err.html("");
  if(confirm("下线后将不接受新连接,但会继续处理当前连接,是否继续?")){
	  var args = {"host":host,"port":port};
	  $.get("/admin/lb/delHost",args,function(res){
	      err.html(res.info || res);
	      location.reload();
	  });   
  }   
}

/*保存负载均衡全局参数*/
function saveLbGlobArg(){
  var err = $("#err_info");
  var port = $("#lb_port").val();
  if(!port||isNaN(port)||port<1||port>65535)
     return err.html("代理端口范围:[1-65535]");
     
  err.html("");
  if(confirm("修改全局参数会导致服务重启,是否继续?")){
	  var args = {"type":"ip_hash","port":port};
	  $.get("/admin/lb/addGlob",args,function(res){
	       if(res.code==200)
         	 location.reload();
    	   else
             err.html(res.info || res)
	  });   
  }
}

/*添加目标主机*/
function addHost(){
  var reg = /^(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])$/;
  var weight = $("#weight").val();
  var host = $("#host").val();
  var port = $("#port").val();
  var err = $("#err_info");
  if(!weight||!host||!port)
    return err.html("主机、端口、权重不能为空");
    
  if(!reg.test(host))
     return err.html("主机必须是一个有效的IP地址");
       
  if(isNaN(port)||isNaN(weight))
     return err.html("端口、权重必须为数字");
  
  if(port<1||port>65535)
     return err.html("端口范围:[1-65535]");
  
  if(weight<1||weight>10)
     return err.html("权重范围:[1-10]");   
        
  err.html("");
  var args = {"host":host,"port":port,"weight":weight};
  $.get("/admin/lbadd",args,function(res){
     if(res.code==200)
         location.reload();
    else
      err.html(res.info || res)
  });
}

