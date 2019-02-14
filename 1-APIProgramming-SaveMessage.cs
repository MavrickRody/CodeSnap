// this controller is for managing messages and announcement
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using PDSAPI.Models;
using PDSRepository.iRepository;
using PDSRepository.Models;
using PDSRepository.Repository;
namespace PDSAPI.Controllers
{
    [RoutePrefix("api/Message")]
    public class MessageApiController : ApiController
    {
        /// <summary>
        /// GetUserName
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [Route("GetUserName")]
        public IEnumerable<UserProfile> GetUserName()
        {

            messageRepository uInfo = new messageRepository();
            IEnumerable<UserProfile> uProfile = uInfo.GetUserName();
            if (uProfile != null)
                return uProfile;
            else
                return null;
        }

        /// <summary>
        /// GetUserNameFrAnnouncment
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [Route("GetUserNameFrAnnouncment")]
        public IEnumerable<UserProfile> GetUserNameFrAnnouncment()
        {
            messageRepository uInfo = new messageRepository();
            IEnumerable<UserProfile> uProfile = uInfo.GetUserNameFrAnnouncment();
            if (uProfile != null)
                return uProfile;
            else
                return null;
        }
        
        /// <summary>
        /// saveUserMessage
        /// </summary>
        /// <param name="msfinfo"></param>
        [HttpPost]
        [Route("SaveMessage")]
        public Messages saveUserMessage(Newtonsoft.Json.Linq.JObject msfinfo)
        {
            Messages messageSchedule = msfinfo.ToObject<Messages>();
            using (Imessages ce = new messageRepository())
            {
                return ce.SaveMessage(messageSchedule);
            }
        }

        /// <summary>
        /// SaveMessageFrAnnouncment
        /// </summary>
        /// <param name="msinfo"></param>
        [HttpPost]
        [Route("SaveMessageFrAnnouncment")]
        public void SaveAnnocMessage(Newtonsoft.Json.Linq.JObject msinfo)
        {
            Announcement messageSchedule = msinfo.ToObject<Announcement>();
            using (Imessages ce = new messageRepository())
            {
                ce.SaveMessageFrAnnouncment(messageSchedule);
            }
        }
    }
}
