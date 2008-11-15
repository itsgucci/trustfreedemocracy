<?php
if ($_POST['email']) {
	$addresses = explode(',', $_POST['email']);
	foreach ($addresses as $address) {
		
		$message = "
Aloha,

Have you heard about Real Democracy? Having a voice in legislature is now easier than email!

Appropriate your tax dollars where you think they are appropriate. Discover the true priority of our community. Introduce motions for the changes you would like to see. Support and discuss issues with fellow community members.
			
The time is now, the power is Yours. You can do all this and more at www.TrustFreeDemocracy.com

TrustFreeDemocracy
";

		// wrap long lines
		$message = wordwrap($message, 70);
		
		mail($address, "I Want Real Democracy", $message, 'From: Thomas Jefferson <aloha@iwantrealdemocracy.com>' . "\r\n");
	}
?>
<html>
<body>
	<p>Emails have been successfully sent.</p>
	<p>Thank you for helping out!</p>
	<p><a href="http://iwantrealdemocracy.com">Return to the Homepage</a></p>
  <script type="text/javascript">
  var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
  document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
  </script>
  <script type="text/javascript">
  var pageTracker = _gat._getTracker("UA-1655471-7");
  pageTracker._initData();
  pageTracker._trackPageview();
  </script>
</body>
</html>
<?php
}
else {
?>
	<p>Unfortunately sending the emails has failed.</p>
<?php
}
?>
