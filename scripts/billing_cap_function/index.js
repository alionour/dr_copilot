const {CloudBillingClient} = require('@google-cloud/billing');

exports.stopBilling = async (pubSubEvent, context) => {
  const pubSubData = JSON.parse(Buffer.from(pubSubEvent.data, 'base64').toString());
  
  if (pubSubData.costAmount <= pubSubData.budgetAmount) {
    console.log(`No action necessary. Cost: $${pubSubData.costAmount}, Budget: $${pubSubData.budgetAmount}`);
    return `No action necessary`;
  }

  const projectId = process.env.GOOGLE_CLOUD_PROJECT;
  const projectName = `projects/${projectId}`;
  const billingClient = new CloudBillingClient();

  try {
    const [billingInfo] = await billingClient.getProjectBillingInfo({ name: projectName });

    if (billingInfo.billingEnabled) {
      console.log(`Disabling billing for project: ${projectId}`);
      await billingClient.updateProjectBillingInfo({
        name: projectName,
        projectBillingInfo: { billingAccountName: '' }, 
      });
      console.log(`Billing successfully disabled.`);
    } else {
      console.log(`Billing is already disabled.`);
    }
  } catch (error) {
    console.error('Error disabling billing:', error);
  }
};
